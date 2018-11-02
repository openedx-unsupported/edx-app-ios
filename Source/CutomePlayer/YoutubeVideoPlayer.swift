//
//  YoutubeVideoPlayer.swift
//  edX
//
//  Created by Andrey on 9/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

class YoutubeVideoPlayer: VideoPlayer{

    let playerView: YTPlayerView
    let background: UIColor
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
        videoPlayerProtraitView(portraitView: UIDevice.current.orientation.isPortrait)
        view.addSubview(playerView)
        UINavigationBar.appearance().barTintColor = .black
        t_captionLanguage = String(Locale.preferredLanguages[0].prefix(2))
    }

    func videoPlayerProtraitView(portraitView: Bool){
        let screenSize: CGRect = UIScreen.main.bounds

        if portraitView{
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.width * 9 / 16)
        }
        else{
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }

    override func play(video: OEXHelperVideoDownload) {
        super.setVideo(video: video)
        guard let videoUrl = video.summary?.videoURL else{
            Logger.logError("YOUTUBE_VIDEO", "invalid url")
            return
        }
        guard let url = URLComponents(string : videoUrl) else {
            Logger.logError("YOUTUBE_VIDEO", "invalid url")
            return
        }
        let playvarsDic = ["playsinline": 1, "autohide": 1, "fs": 0, "showinfo": 0, ]

        videoId = (url.queryItems?.first?.value)!
        playerView.load(withVideoId: videoId, playerVars: playvarsDic)
    }
 }

extension YoutubeVideoPlayer {

    override func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        videoPlayerProtraitView(portraitView: !fullscreen)
        playerView.playVideo()

    }
}

extension YoutubeVideoPlayer: YTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        // call play video when the player is finished loading.
        self.playerView.playVideo()
    }
}
