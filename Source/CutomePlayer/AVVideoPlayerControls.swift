//
//  AVVideoPlayerControls.swift
//  edX
//
//  Created by Salman on 06/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import CoreMedia

protocol VideoPlayerControlsDelegate {
    func playPausePressed(isPlaying: Bool)
    func seekBackwardPressed()
    func fullscreenPressed()
}

class AVVideoPlayerControls: UIView, CLButtonDelegate, VideoPlayerSettingsDelegate {
    
    var video : OEXHelperVideoDownload? {
        didSet {
            startBufferedTimer()
        }
    }
    private var playerSettings : OEXVideoPlayerSettings = OEXVideoPlayerSettings()
    private var playerRateBeforeSeek: Float = 0
    private var isControlsHidden: Bool = true
    private let subTitleParser = SubTitleParser()
    private var subtitleActivated : Bool = false
    private var bufferedTimer: Timer?
    private lazy var dismissOptionOverlayButton: CLButton = CLButton()
    private lazy var timeElapsedLabel: UILabel = UILabel()
    private lazy var seekForwardButton: UILabel = UILabel()
    private var lastElapsedTime: Float64 = 0.0
    private var dataInterface = OEXInterface.shared()
    let videoPlayerController: AVVideoPlayer
    var delegate : VideoPlayerControlsDelegate?
    var seeking: Bool = false
    
    var leftSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .left
        return gesture
    }()
    
    var rightSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .right
        return gesture
    }()
    
    var playerStartTime: TimeInterval = 0
    var playerStopTime: TimeInterval = 0
    let videoSkipBackwardsDuration: Double = 30
    
    lazy private var subTitleLabel : UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 31.0/255.0, green: 33.0/255.0, blue: 36.0/255.0, alpha: 0.4)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.layer.cornerRadius = 5
        label.layer.rasterizationScale = UIScreen.main.scale
        label.textAlignment = NSTextAlignment.center
        label.font = OEXStyles.shared().sansSerif(ofSize: 12)
        label.layer.shouldRasterize = true
        return label
    }()
    
    lazy private var topBar: UIView = {
        let view = UIView()
        view.backgroundColor = self.barColor
        view.alpha = 0
        return view
    }()
    
    lazy private var tapButton: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.contentTapped()
            }, for: .touchUpInside)
        return button
    }()
    
    lazy private var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = self.barColor
        return view
    }()
    
    lazy private var rewindButton: CLButton = {
        let button = CLButton()
        button.setImage(UIImage.RewindIcon(), for: .normal)
        button.tintColor = .white
        button.delegate = self
        button.addTarget(self, action: #selector(seekBackwardPressed), for: .touchUpInside)
        return button
    }()
    
    lazy private var durationSlider: CustomSlider = {
        let slider = CustomSlider()
        slider.isContinuous = true
        slider.setThumbImage(UIImage(named: "ic_seek_thumb"), for: .normal)
        slider.setMinimumTrackImage(UIImage(named: "ic_progressbar.png"), for: .normal)
        slider.secondaryTrackColor = UIColor(red: 76.0/255.0, green: 135.0/255.0, blue: 130.0/255.0, alpha: 0.9)
        slider.addTarget(self, action: #selector(durationSliderValueChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(durationSliderTouchBegan), for: .touchDown)
        slider.addTarget(self, action: #selector(durationSliderTouchEnded), for: .touchUpInside)
        slider.addTarget(self, action: #selector(durationSliderTouchEnded), for: .touchUpOutside)
        return slider
    }()
    
    lazy private var btnSettings: CLButton = {
        let button = CLButton()
        button.setImage(UIImage.SettingsIcon(), for: .normal)
        button.tintColor = .white
        button.delegate = self
        button.addTarget(self, action: #selector(settingsButtonClicked), for: .touchUpInside)
        return button
    }()
    
    lazy private var tableSettings: UITableView = {
        let tableView = self.playerSettings.optionsTable
        tableView.isHidden = true
        self.playerSettings.delegate = self
        return tableView
    }()
    
    lazy private var playPauseButton : AccessibilityCLButton = {
        let button = AccessibilityCLButton()
        button.setAttributedTitle(title: UIImage.PauseTitle(), forState: .normal, animated: true)
        button.setAttributedTitle(title: UIImage.PlayTitle(), forState: .selected, animated: true)
        button.addTarget(self, action: #selector(playPausePressed), for: .touchUpInside)
        button.delegate = self;
        return button
    }()
    
    lazy private var btnNext: CLButton = {
        let button = CLButton()
        button.setImage(UIImage(named: "ic_next"), for: .normal)
        button.setImage(UIImage(named: "ic_next_press"), for: .highlighted)
        button.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
        button.delegate = self;
        return button
    }()
    
    lazy private var btnPrevious: CLButton = {
        let button = CLButton()
        button.setImage(UIImage(named: "ic_previous"), for: .normal)
        button.setImage(UIImage(named: "ic_previous_press"), for: .highlighted)
        button.addTarget(self, action: #selector(previousButtonClicked), for: .touchUpInside)
        button.delegate = self;
        return button
    }()
    
    lazy private var fullScreenButton: CLButton = {
        let button = CLButton()
        button.setImage(UIImage.ExpandIcon(), for: .normal)
        button.tintColor = .white
        button.delegate = self
        button.addTarget(self, action: #selector(fullscreenPressed), for: .touchUpInside)
        return button
    }()
    
    lazy private var timeRemainingLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textColor = .lightText
        label.textAlignment = .center
        label.text = Strings.videoPlayerDefaultRemainingTime
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 1
        label.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        label.layer.shadowOpacity = 0.8
        label.font = OEXStyles.shared().semiBoldSansSerif(ofSize: 12.0)
        return label
    }()
    
    lazy private var videoTitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = OEXStyles.shared().semiBoldSansSerif(ofSize: 16.0)
        label.textAlignment = .left
        label.textColor = .white
        label.text = Strings.untitled
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 1
        label.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        label.layer.shadowOpacity = 0.8
        return label
    }()

    private var barColor: UIColor {
        return UIColor.black.withAlphaComponent(0.7)
    }
    
    init(with player: AVVideoPlayer) {
        videoPlayerController = player
        super.init(frame: CGRect.zero)
        seeking = false
        playerSettings.delegate = self
        backgroundColor = .clear
        addSubviews()
        hideAndShowControls(isHidden: isControlsHidden)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        addSubview(topBar)
        topBar.addSubview(videoTitleLabel)
        addSubview(bottomBar)
        bottomBar.addSubview(rewindButton)
        bottomBar.addSubview(durationSlider)
        bottomBar.addSubview(timeRemainingLabel)
        bottomBar.addSubview(btnSettings)
        bottomBar.addSubview(fullScreenButton)
        addSubview(btnNext)
        addSubview(btnPrevious)
        addSubview(tapButton)
        addSubview(playPauseButton)
        addSubview(subTitleLabel)
        addSubview(tableSettings)
        setConstraints()
        setPlayerControlAccessibilityID()
    }
    
    var durationSliderValue: Float {
        set {
            durationSlider.value = newValue
        }
        get {
            return durationSlider.value
        }
    }
    
    var isTapButtonHidden: Bool {
        set {
            tapButton.isHidden = newValue
        }
        get {
            return tapButton.isHidden
        }
    }
    
    private func startBufferedTimer() {
        stopBufferedTimer()
        bufferedTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(monitorBufferedMovie), userInfo: nil, repeats: true)
        if let timer = bufferedTimer {
            RunLoop.current.add(timer, forMode: .defaultRunLoopMode)
        }
    }
    
    private func stopBufferedTimer() {
        if let timer = bufferedTimer, timer.isValid {
            bufferedTimer?.invalidate()
        }
    }
    
    private func setConstraints() {
        bottomBar.snp_makeConstraints { make in
            make.leading.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(50)
        }
        
        rewindButton.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin)
            make.height.equalTo(25.0)
            make.width.equalTo(25.0)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        durationSlider.snp_makeConstraints { make in
            make.leading.equalTo(rewindButton.snp_trailing).offset(10.0)
            make.height.equalTo(34.0)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        timeRemainingLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        timeRemainingLabel.snp_makeConstraints { make in
            make.leading.equalTo(durationSlider.snp_trailing).offset(10.0)
            make.centerY.equalTo(bottomBar.snp_centerY)
            make.width.equalTo(75)
            make.height.equalTo(34)
        }
        
        btnSettings.snp_makeConstraints { make in
            make.leading.equalTo(timeRemainingLabel.snp_trailing).offset(10.0)
            make.height.equalTo(24.0)
            make.width.equalTo(24.0)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        fullScreenButton.snp_makeConstraints { make in
            make.leading.equalTo(btnSettings.snp_trailing).offset(10.0)
            make.height.equalTo(20.0)
            make.width.equalTo(20.0)
            make.trailing.equalTo(self).inset(10)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        tableSettings.snp_makeConstraints { make in
            make.height.equalTo(100)
            make.width.equalTo(110)
            make.bottom.equalTo(btnSettings.snp_top).offset(-10)
            make.centerX.equalTo(btnSettings.snp_centerX).offset(-50)
        }
        
        tapButton.snp_makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(bottomBar.snp_top)
        }
        
        playPauseButton.snp_makeConstraints { make in
            make.center.equalTo(tapButton.center)
        }
        
        subTitleLabel.snp_makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp_top).offset(30)
            make.centerX.equalTo(snp_centerX)
            make.leadingMargin.greaterThanOrEqualTo(16)
            make.trailingMargin.lessThanOrEqualTo(16)
        }
    }
    
    private func setPlayerControlAccessibilityID() {
         durationSlider.accessibilityLabel = Strings.accessibilitySeekBar
         btnPrevious.accessibilityLabel = Strings.previous
         btnNext.accessibilityLabel = Strings.next
         rewindButton.accessibilityLabel = Strings.accessibilityRewind
         rewindButton.accessibilityHint = Strings.accessibilityRewindHint
         btnSettings.accessibilityLabel = Strings.accessibilitySettings
         fullScreenButton.accessibilityLabel = Strings.accessibilityFullscreen
         tapButton.isAccessibilityElement = false
    }

    private func updateSubtTitleConstraints() {
        subTitleLabel.snp_updateConstraints { make in
            let bottomOffset = isControlsHidden ? 30 : -StandardVerticalMargin
            make.bottom.equalTo(bottomBar.snp_top).offset(bottomOffset)
        }
    }
    
    @objc private func autoHide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(hideAndShowControls(isHidden:)), with: 1, afterDelay: 3.0)
    }
    
    @objc func hideAndShowControls(isHidden: Bool) {
        isControlsHidden = isHidden
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            let alpha: CGFloat = isHidden ? 0 : 1
            self?.topBar.alpha = alpha
            self?.bottomBar.alpha = alpha
            self?.bottomBar.isUserInteractionEnabled = !isHidden
            self?.playPauseButton.alpha = alpha
            self?.playPauseButton.isUserInteractionEnabled = !isHidden
            self?.btnPrevious.alpha = alpha
            self?.btnNext.alpha = alpha
            self?.btnNext.isUserInteractionEnabled = !isHidden
            self?.btnPrevious.alpha = alpha
            self?.btnPrevious.isUserInteractionEnabled = !isHidden
            if (!isHidden) {
                self?.autoHide()
            }
            
        }) {[weak self] _ in
            self?.updateSubtTitleConstraints()
        }
    }
    
    func hideOptionsAndValues() {
        tableSettings.isHidden = true
    }
    
    func updateTimeLabel(elapsedTime: Float64, duration: Float64) {
        let totalTime: Float64 = CMTimeGetSeconds(videoPlayerController.duration)
        timeRemainingLabel.text = String(format: "%02d:%02d / %02d:%02d", ((lround(elapsedTime) / 60) % 60), lround(elapsedTime) % 60, ((lround(totalTime) / 60) % 60), lround(totalTime) % 60)
        if subtitleActivated {
            subTitleLabel.text = videoPlayerController.videoSubTitle?.getSubTitle(at: elapsedTime)
        }
    }
    
    // MARK: Slider Handling
    @objc private func durationSliderValueChanged() {
        let videoDuration = CMTimeGetSeconds(videoPlayerController.duration)
        let elapsedTime: Float64 = videoDuration * Float64(durationSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    @objc private func durationSliderTouchBegan() {
        playerStartTime = videoPlayerController.currentTime
        videoPlayerController.pause()
    }
    
    @objc private func durationSliderTouchEnded() {
        let videoDuration = CMTimeGetSeconds(videoPlayerController.duration)
        let elapsedTime: Float64 = videoDuration * Float64(durationSlider.value)
        updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        
        videoPlayerController.videoPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 100)) { [weak self]
            (completed: Bool) -> Void in
            self?.videoPlayerController.videoPlayer.play()
        }
        
        playerStopTime = videoPlayerController.currentTime
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoSeekRewind(videoId, requestedDuration:playerStopTime - playerStartTime, oldTime:playerStartTime, newTime: playerStopTime, courseID: courseId, unitURL: unitUrl, skipType: "slide")
        }
    }
    
    @objc private func seekBackwardPressed() {
        delegate?.seekBackwardPressed()
    }
    
    @objc private func playPausePressed() {
        playPauseButton.isSelected = !playPauseButton.isSelected
        delegate?.playPausePressed(isPlaying: playPauseButton.isSelected)
        autoHide()
    }
    
    @objc private func fullscreenPressed() {
        autoHide()
        delegate?.fullscreenPressed()
    }
    
    private func contentTapped() {
        if tableSettings.isHidden {
            hideAndShowControls(isHidden: !isControlsHidden)
        }
        else {
            tableSettings.isHidden = true
            autoHide()
        }
    }
    @objc private func nextButtonClicked() {
        autoHide()
    }
    @objc private func previousButtonClicked() {
        autoHide()
    }
    
    @objc private func settingsButtonClicked() {
        NSObject.cancelPreviousPerformRequests(withTarget:self)
        tableSettings.isHidden = !tableSettings.isHidden
    }
    
    func showSubSettings(chooser: UIAlertController) {
        let controller = UIApplication.shared.keyWindow?.rootViewController
        chooser.configurePresentationController(withSourceView: btnSettings)
        controller?.present(chooser, animated: true, completion: nil)
    }
    
    func setCaption(language: String) {
        OEXInterface.setCCSelectedLanguage(language)
        if language == "" {
            deAvtivateSubTitles()
            return
        }
        else {
            activateSubTitles()
            if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
                OEXAnalytics.shared().trackTranscriptLanguage(videoId, currentTime: videoPlayerController.currentTime, language: language, courseID: courseId, unitURL: unitUrl)
            }
        }
    }
    
    func setPlaybackSpeed(speed: OEXVideoSpeed) {
        let oldSpeed = videoPlayerController.rate
        let playbackRate = OEXInterface.getOEXVideoSpeed(speed)
        OEXInterface.setCCSelectedPlaybackSpeed(speed)
        videoPlayerController.rate = playbackRate
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoSpeed(videoId, currentTime: videoPlayerController.currentTime, courseID: courseId, unitURL: unitUrl, oldSpeed: String.init(format: "%.1f", oldSpeed), newSpeed: String.init(format: "%.1f", playbackRate))
        }
    }
    
    //MARK Video player setting delegate method
    func videoInfo() -> OEXVideoSummary? {
        return video?.summary
    }
    
    func activateSubTitles() {
        subtitleActivated = true
        showSubtiles(show: true)
        OEXAnalytics.shared().trackShowTranscript(video?.summary?.videoID ?? "", currentTime: videoPlayerController.currentTime, courseID: video?.course_id ?? "", unitURL: video?.summary?.unitURL ?? "")
    }

    func deAvtivateSubTitles() {
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackHideTranscript(videoId, currentTime: videoPlayerController.currentTime, courseID: courseId, unitURL: unitUrl)
        }
        dataInterface.selectedCCIndex = -1
        subTitleLabel.text = ""
        subtitleActivated = false
        showSubtiles(show: false)
    }
    
    private func showSubtiles(show: Bool) {
        subTitleLabel.isHidden = !show;
    }
    
    @objc private func monitorBufferedMovie() {
        let secondaryProgress = floor(videoPlayerController.playableDuration)
        let totalTime = floor(videoPlayerController.duration.seconds)
        let time = secondaryProgress/totalTime
        if time.isNaN {
            if !videoPlayerController.videoPlayer.isPlaying {
             stopBufferedTimer()
            }
        }
        durationSlider.secondaryProgress = Float(time)
    }
    
    func addGesters() {
        if let _ = videoPlayerController.playerView.gestureRecognizers?.contains(leftSwipeGestureRecognizer), let _ = videoPlayerController.playerView.gestureRecognizers?.contains(rightSwipeGestureRecognizer) {
            removeGesters()
        }
    
        leftSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.nextBtnClicked()
        }
        rightSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.previousBtnClicked()
        }
        videoPlayerController.playerView.addGestureRecognizer(leftSwipeGestureRecognizer )
        videoPlayerController.playerView.addGestureRecognizer(rightSwipeGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(videoPlayerController.currentTime), mode: true, unitURL: unitUrl)
        }
    }
    
    func removeGesters() {
        videoPlayerController.playerView.removeGestureRecognizer(leftSwipeGestureRecognizer)
        videoPlayerController.playerView.removeGestureRecognizer(rightSwipeGestureRecognizer)
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(videoPlayerController.currentTime), mode: false, unitURL: unitUrl)
        }
    }
    
    private func nextBtnClicked() {
        dataInterface.selectedCCIndex = -1;
        dataInterface.selectedVideoSpeedIndex = -1;
        videoPlayerController.resetView()
        NotificationCenter.default.post(name: Notification.Name(rawValue:NOTIFICATION_VIDEO_PLAYER_NEXT), object: self)
    }
    
    private func previousBtnClicked() {
        dataInterface.selectedCCIndex = -1;
        dataInterface.selectedVideoSpeedIndex = -1;
        videoPlayerController.resetView()
        NotificationCenter.default.post(name: Notification.Name(rawValue:NOTIFICATION_VIDEO_PLAYER_PREVIOUS), object: self)
    }
}
