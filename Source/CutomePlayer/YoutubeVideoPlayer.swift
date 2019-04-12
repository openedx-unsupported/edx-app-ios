//
//  YoutubeVideoPlayer.swift
//  edX
//
//  Created by Andrey on 9/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

class YoutubeVideoPlayer: VideoPlayer {

    let playerView: YTPlayerView
    private let background: UIColor
    var videoId: String

    override var currentTime: TimeInterval {
        return Double(playerView.currentTime())
    }
    override init(environment : Environment) {
        playerView = YTPlayerView()
        videoId = String()
        background = environment.styles.neutralWhite()
        super.init(environment: environment)
        playerView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createYoutubePlayer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        UINavigationBar.appearance().barTintColor = background
    }

    private func createYoutubePlayer() {
        videoPlayerPortraitView(portraitView: UIDevice.current.orientation.isPortrait)
        view.addSubview(playerView)
        UINavigationBar.appearance().barTintColor = .black
        t_captionLanguage = String(Locale.preferredLanguages[0].prefix(2))
    }

    func videoPlayerPortraitView(portraitView: Bool) {
        let screenSize: CGRect = UIScreen.main.bounds

        if portraitView {
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.width * 9 / 16)
        }
        else {
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }

    override func play(video: OEXHelperVideoDownload) {
        super.setVideo(video: video)
        guard let videoUrl = video.summary?.videoURL, let url = URLComponents(string : videoUrl) else {
            Logger.logError("YOUTUBE_VIDEO", "invalid url")
            return
        }

        let playvarsDic = ["playsinline": 1, "autohide": 1, "fs": 0, "showinfo": 0]

        guard let id = url.queryItems?.first?.value else {
            return
        }
        videoId = id
        playerView.load(withVideoId: videoId, playerVars: playvarsDic)
    }
    
    override func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        let currentTime = Int(playerView.currentTime())
        
        var playVars = ["playsinline": 1, "autohide": 1, "fs": 0, "showinfo": 0, "start": currentTime]
        
        if fullscreen {
            playVars.setObjectOrNil(0, forKey: "playsinline")
        }
        else {
            playerView.webView?.loadHTMLString("", baseURL: nil)
        }
        playerView.load(withVideoId: videoId, playerVars: playVars)
        videoPlayerPortraitView(portraitView: !fullscreen)
        
    }
    
    override func seek(to time: Double) {
        playerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
 }

extension YoutubeVideoPlayer: YTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        // call play video when the player is finished loading.
        playerView.playVideo()
    }

}
