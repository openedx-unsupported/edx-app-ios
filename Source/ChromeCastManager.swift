//
//  ChromeCastManager.swift
//  edX
//
//  Created by Muhammad Umer on 10/9/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

/// This Protocol handles communication between ChromecastManager and Controller which implements it,
/// It allows to lisen for connection states, i.e
/// ConnectedToChromeCast, DisconnectedFromChromeCast, StartPlayingOnChromeCast, FinishedPlayingOnChromecast
protocol ChromeCastPlayerStatusDelegate: AnyObject {
    func chromeCastDidConnect()
    func chromeCastDidDisconnect(playedTime: TimeInterval)
    func chromeCastVideoPlaying()
    func chromeCastDidFinishPlaying()
}

private enum DelegateCallbackType: Int {
    case connect, disconnect, playing, paused, finished, none
}

/// This class ChromeCastManager is a singleton class and it is taking care of all the chrome cast related functionality
@objc class ChromeCastManager: NSObject, GCKSessionManagerListener, GCKDiscoveryManagerListener, GCKRemoteMediaClientListener, GCKCastDeviceStatusListener  {
    
    typealias Environment = OEXInterfaceProvider & OEXAnalyticsProvider
    
    @objc static let shared = ChromeCastManager()
    private let context = GCKCastContext.sharedInstance()
    
    private var delegates: [ChromeCastPlayerStatusDelegate] = []
    private var discoveryManager: GCKDiscoveryManager?
    var sessionManager: GCKSessionManager?
    private var streamPosition: TimeInterval {
        return sessionManager?.currentSession?.remoteMediaClient?.mediaStatus?.streamPosition ?? .zero
    }
    
    private var idleReason: GCKMediaPlayerIdleReason {
        let remoteMediaClient = sessionManager?.currentCastSession?.remoteMediaClient
        return remoteMediaClient?.mediaStatus?.idleReason ?? .none
    }
    
    var video: OEXHelperVideoDownload?
    
    var isConnected: Bool {
        return sessionManager?.hasConnectedCastSession() ?? false
    }
    
    var isAvailable: Bool {
        return discoveryManager?.deviceCount ?? 0 > 0
    }
    
    var currentPlayingVideoCourseID: String? {
        return sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.metadata?.string(forKey: ChromeCastCourseID)
    }
    
    private var callbackType: DelegateCallbackType = .none {
        didSet {
            if oldValue != callbackType {
                trackEvent(for: callbackType)
            }
            delegateCallBacks()
        }
    }
    /// Chrome cast SDK is not giving callbacks for the clicks of GCKUICastButton and GCKUIMiniMediaControlsViewController
    var viewExpanded = false
    
    var isMiniPlayerAdded = false
    // Chrome cast SDK takes some time to initilize itself. First call to any functionality of chrome cast is being sent with a delay
    // This is used to track either the first request is being sent or not
    fileprivate var isInitilized = false
    
    private var playedTime: TimeInterval = 0.0
    
    private var environment: Environment?
    
    private override init() {
        super.init()
    }
    
    @objc func configure(environment: Environment) {
        self.environment = environment
        discoveryManager = context.discoveryManager
        discoveryManager?.add(self)
        sessionManager = context.sessionManager
        sessionManager?.add(self)
        discoveryManager?.passiveScan = true
        discoveryManager?.startDiscovery()
    }
    
    func add(delegate: ChromeCastPlayerStatusDelegate) {
        let contains = delegates.filter { $0 === delegate }
        if contains.count > 0 { return }
        delegates.append(delegate)
    }
    
    func remove(delegate: ChromeCastPlayerStatusDelegate) {
        let objectIndex = delegates.firstIndexMatching { $0 === delegate }
        guard let index = objectIndex else { return }
        delegates.remove(at: index)
    }
    
    private func addMediaListner() {
        guard let currentSession = sessionManager?.currentCastSession else { return }
        currentSession.add(self)
        currentSession.remoteMediaClient?.add(self)
    }
    
    private func removeMediaListener() {
        guard let currentSession = sessionManager?.currentCastSession else { return }
        currentSession.remoteMediaClient?.remove(self)
    }
    
    private func delegateCallBacks() {
        for delegate in delegates {
            switch callbackType {
            case .connect:
                delegate.chromeCastDidConnect()
                environment?.analytics.trackChromecastConnected()
                break
            case .disconnect:
                delegate.chromeCastDidDisconnect(playedTime: playedTime)
                environment?.analytics.trackChromecastDisconnected()
                break
            case .playing:
                playedTime = streamPosition
                delegate.chromeCastVideoPlaying()
                break
            case .finished:
                playedTime = 0.0
                delegate.chromeCastDidFinishPlaying()
                break
            default:
                break
            }
        }
    }
    
    private func saveStreamProgress() {
        guard let metadata = sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.metadata,
            let videoID = metadata.string(forKey: ChromeCastVideoID),
            let videoData = environment?.interface?.videoData(forVideoID: videoID),
            let duration = Double(videoData.duration), streamPosition > 1  else { return }
        // remoteMediaClient didUpdate called on buffering initilized with stream position 0 and then seek happen if there is any. If user switched in between two update calls then video stream progress marked override last played value
        
        environment?.interface?.markLastPlayedInterval(Float(streamPosition), forVideoID: videoID)
        let state = doublesWithinEpsilon(left: duration, right: playedTime) ? OEXPlayedState.watched : OEXPlayedState.partiallyWatched
        environment?.interface?.markVideoState(state, forVideoID: videoID)
    }
    
    private func trackEvent(for type: DelegateCallbackType) {
        guard let video = video,
            let metadata = sessionManager?.currentCastSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.metadata,
            let videoID = metadata.string(forKey: ChromeCastVideoID),
            video.summary?.videoID == videoID else { return }
        
        guard type == .playing || type == .paused else { return }
        let state: OEXVideoState = type == .playing ? .play : .pause
        environment?.interface?.sendAnalyticsEvents(state, withCurrentTime: streamPosition, forVideo: video, playMedium: AnalyticsEventDataKey.PlayMediumChromecast.rawValue)
    }
    
    //MARK:- GCKSessionManager methods
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        DispatchQueue.main.async { [weak self] in
            self?.addMediaListner()
            self?.callbackType = .connect
        }
    }
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.removeMediaListener()
            self?.callbackType = .disconnect
        }
    }
    
    //MARK:- GCKRemoteMediaClient methods
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }

        let playerState = mediaStatus.playerState
        switch playerState {
        case .paused:
            callbackType = .paused
            break
        case .idle:
            switch idleReason {
            case .none:
                break
            default:
                DispatchQueue.main.async { [weak self] in
                    self?.callbackType = .finished
                }
            }
        case .playing:
            DispatchQueue.main.async { [weak self] in
                self?.callbackType = .playing
            }
            
            saveStreamProgress()
        default:
            break
        }
    }
}
