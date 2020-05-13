//
//  ChromeCastMiniPlayer.swift
//  edX
//
//  Created by Muhammad Umer on 10/29/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

let ChromeCastMiniPlayerHeight: CGFloat = 60

enum ChromeCastContentType: String {
    case mp4 = "videos/mp4"
    case hls = "application/x-mpegurl"
    case defalut = "videos/*"
}

private enum KnownVideoType: String {
    case mp4 = "mp4"
    case hls = "m3u8"
    case none = ""
}

typealias ChromeCastItemSuccessCompletion = () -> ()
typealias ChromeCastItemFailureCompletion = (Error) -> ()

class ChromeCastMiniPlayer: UIViewController {

    typealias Envoirnment = OEXInterfaceProvider & NetworkManagerProvider

    private let environment : Envoirnment
    private var video: OEXHelperVideoDownload?
    private var containerView = UIView()
    private var mediaController = GCKUIMiniMediaControlsViewController()
    private var courseImageURLString: String {
        guard let courseID = self.video?.course_id, let course = environment.interface?.enrollmentForCourse(withID: courseID)?.course else { return "" }
        
        guard let relativeImageURL = course.courseImageURL,
            let imageURL = URL(string: relativeImageURL, relativeTo: self.environment.networkManager.baseURL) else { return ""}
        
        return imageURL.absoluteString
    }
    
    init(environment: Envoirnment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createContainer()
        createMediaController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func cast(_ video: OEXHelperVideoDownload, _ url: URL, _ videoID: String, _ time: TimeInterval, _ completion: ChromeCastItemSuccessCompletion, _ failure: ChromeCastItemFailureCompletion) {
        self.video = video
        let thumbnail = video.summary?.videoThumbnailURL ?? courseImageURLString
        let mediaInfo = mediaInformation(contentID: url.absoluteString, title: video.summary?.name ?? "", videoID: videoID, contentType: contentType(url: url.absoluteString), streamType: .buffered, thumbnailUrl: thumbnail)
        
        play(with: mediaInfo, at: time, completion: completion)
    }
    
    func play(video: OEXHelperVideoDownload, time: TimeInterval, _ completion: ChromeCastItemSuccessCompletion, _ failure: ChromeCastItemFailureCompletion) {
        guard let videoURL = video.summary?.videoURL,
            let url = URL(string: videoURL),
            let videoID = video.summary?.videoID else { return }
        
        if video.summary?.isYoutubeVideo ?? false {
            YoutubeLink.extract(for: .urlString(videoURL), success: { [weak self] videoInformation in
                guard let link = videoInformation.highestQualityPlayableLink,
                    let youtubeUrl = URL(string: link) else {
                        failure(YoutubeLinkExtractorError.unkown)
                        return
                }
                self?.cast(video, youtubeUrl, videoID, time, completion, failure)
                }, failure: { error in
                    failure(error)
            })
        } else {
            cast(video, url, videoID, time, completion, failure)
        }
    }
    
    private func contentType(url: String) -> ChromeCastContentType {
        let components = url.components(separatedBy: ".")
        let videoType = KnownVideoType(rawValue: components.last ?? "") ?? .none
        
        switch videoType {
        case .mp4:
            return .mp4
        case .hls:
            return .hls
        default:
            return .defalut
        }
    }
    
    private func createContainer() {
        containerView = UIView()
        containerView.accessibilityIdentifier = "mediaControlsContainerView"
        view.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
            make.height.equalTo(ChromeCastMiniPlayerHeight)
        }
    }
    
    private func createMediaController() {
        let castContext = GCKCastContext.sharedInstance()
        mediaController = castContext.createMiniMediaControlsViewController()
        loadViewController(mediaController, inContainerView: containerView)
    }
    
    private func loadViewController(_ viewController: UIViewController?, inContainerView containerView: UIView) {
        guard let viewController = viewController else { return }
        addChild(viewController)
        viewController.view.frame = containerView.bounds
        containerView.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    private func mediaInformation(contentID: String, title: String, videoID: String, contentType: ChromeCastContentType, streamType: GCKMediaStreamType, thumbnailUrl: String?) -> GCKMediaInformation {
        let deviceName = ChromeCastManager.shared.sessionManager?.currentCastSession?.device.friendlyName
        
        return GCKMediaInformation.buildMediaInformation(contentID: contentID, title: title, videoID: videoID, contentType: contentType, streamType: streamType, thumbnailUrl: thumbnailUrl, deviceName: deviceName)
    }
    
    private func play(with mediaInfo: GCKMediaInformation, at time: TimeInterval, completion: ChromeCastItemSuccessCompletion) {
        guard let currentSession = ChromeCastManager.shared.sessionManager?.currentSession,
            !isAlreadyPlaying(mediaInfo: mediaInfo) else {
            return
        }
        
        let options = GCKMediaLoadOptions()
        options.playPosition = time
        currentSession.remoteMediaClient?.loadMedia(mediaInfo, with: options)
        
        completion(true)
    }
    
    private func isAlreadyPlaying(mediaInfo: GCKMediaInformation) -> Bool {
        guard let currentSession = ChromeCastManager.shared.sessionManager?.currentSession, let contentID = currentSession.remoteMediaClient?.mediaStatus?.mediaInformation?.contentID else {
            return false
        }
        
        return (mediaInfo.contentID ?? "") == contentID
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        ChromeCastManager.shared.viewExpanded = true
        super.touchesBegan(touches, with: event)
    }
}
