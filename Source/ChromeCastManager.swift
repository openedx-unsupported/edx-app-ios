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
protocol ChromeCastPlayerStatusDelegate: class {
    func chromeCastDidConnect()
    func chromeCastDidDisconnect()
    func chromeCastVideoPlaying()
    func chromeCastDidFinishPlaying()
}

private enum DelegateCallbackType: Int {
    case connect, disconnect, playing, finished, none
}

/// This class ChromeCastManager is a singleton class and it is taking care of all the chrome cast related functionality
@objc class ChromeCastManager: NSObject, GCKSessionManagerListener, GCKDiscoveryManagerListener, GCKRemoteMediaClientListener, GCKCastDeviceStatusListener  {
    
    typealias Environment = OEXInterfaceProvider
    
    @objc static let shared = ChromeCastManager()
    var delegate: ChromeCastPlayerStatusDelegate?
    private let context = GCKCastContext.sharedInstance()
    private var discoveryManager: GCKDiscoveryManager?
    var sessionManager: GCKSessionManager?
    
    private var streamPosition: TimeInterval {
        return sessionManager?.currentSession?.remoteMediaClient?.mediaStatus?.streamPosition ?? .zero
    }
    
    private var idleReason: GCKMediaPlayerIdleReason {
        let remoteMediaClient = sessionManager?.currentCastSession?.remoteMediaClient
        return remoteMediaClient?.mediaStatus?.idleReason ?? .none
    }
    
    var isConnected: Bool {
        return sessionManager?.hasConnectedCastSession() ?? false
    }
        
    private var callbackType: DelegateCallbackType = .none {
        didSet (value) {
            if value != callbackType {
                delegateCallBacks()
            }
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
    
    private func addMediaListner() {
        guard let currentSession = sessionManager?.currentCastSession else { return }
        currentSession.add(self)
        currentSession.remoteMediaClient?.add(self)
    }
    
    private func removeMediaListener() {
        guard let currentSession = sessionManager?.currentCastSession else { return }
        currentSession.remoteMediaClient?.remove(self)
    }
    
    func showIntroductoryOverlay(items: [UIBarButtonItem]) {
        guard let button = items.first else { return }
        guard let view = button.customView as? GCKUICastButton, !view.isHidden else { return }
        context.presentCastInstructionsViewControllerOnce(with: view)
    }
    
    //MARK:- GCKSessionManager methods
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        DispatchQueue.main.async { [weak self] in
            self?.addMediaListner()
            self?.addChromeCastButton()
            self?.callbackType = .connect
        }
    }
    
    private func delegateCallBacks() {
        switch callbackType {
        case .connect:
            delegate?.chromeCastDidConnect()
            break
        case .disconnect:
            delegate?.chromeCastDidDisconnect()
            break
        case .playing:
            playedTime = streamPosition
            delegate?.chromeCastVideoPlaying()
            break
        case .finished:
            playedTime = 0.0
            delegate?.chromeCastDidFinishPlaying()
            break
        default:
            break
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
    
    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.removeMediaListener()
            self?.callbackType = .disconnect
            self?.removeChromeCastButton()
        }
    }
    
    //MARK:- GCKRemoteMediaClient methods
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        guard let mediaStatus = mediaStatus else { return }

        let playerState = mediaStatus.playerState
        switch playerState {
        case .idle:
            switch idleReason {
            case .none:
                break
            default:
                DispatchQueue.main.async { [weak self] in
                    self?.callbackType = .finished
                }
                saveStreamProgress()
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
        
    //MARK:- ChromeCastButtonDelegate methods
    private func addChromeCastButton() {
        let topViewcontroller = UIApplication.shared.topMostController()
        guard let navController = topViewcontroller?.navigationController as? ForwardingNavigationController else { return }
        
        navController.viewControllers.forEach { [weak self] controller in
            self?.addChromeCastButton(over: controller)
        }
    }
    
    func addChromeCastButton(over controller: UIViewController) {
        guard let controller = controller as? ChromeCastButtonDelegate else { return }
        
        if controller is ChromeCastConnectedButtonDelegate {
            if isConnected {
                controller.addChromeCastButton()
            }
        }
        else {
            controller.addChromeCastButton()
        }
    }
    
    private func removeChromeCastButton() {
        let topViewcontroller = UIApplication.shared.topMostController()
        guard let navController = topViewcontroller?.navigationController as? ForwardingNavigationController else { return }
        
        navController.viewControllers.forEach { [weak self] controller in
            self?.removeChromeCastButton(from: controller)
        }
    }
    
    func removeChromeCastButton(from controller: UIViewController, force: Bool = false) {
        guard let controller = controller as? ChromeCastButtonDelegate else { return }
        
        if force {
            controller.removeChromecastButton()
            return
        }
        
        if controller is ChromeCastConnectedButtonDelegate {
            controller.removeChromecastButton()
        }
    }
    
    func handleCastButton(for controller: UIViewController) {
        guard let _ = controller as? ChromeCastButtonDelegate else { return }
        // Delay of 4 seconds is added as it takes framework to
        // initialize and return true if it has already established connection
        let delay: Double = isInitilized ? 0 : 4
        
        if !isInitilized {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                if !(self?.isInitilized ?? true) && self?.isConnected ?? false {
                    // Add media listner if video is being casted, ideally chromecast SDK shuold configure it automatically but unfortunately, its not configuring media listener. So adding media listner manually
                    self?.addMediaListner()
                }
                self?.isInitilized = true
                self?.addChromeCastButton(over: controller)
            }
        }
        else {
            addChromeCastButton(over: controller)
        }
    }
}
