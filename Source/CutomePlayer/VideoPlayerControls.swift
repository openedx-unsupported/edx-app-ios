//
//  VideoPlayerControls.swift
//  edX
//
//  Created by Salman on 06/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import CoreMedia

protocol VideoPlayerControlsDelegate {
    func playPausePressed(playerControls: VideoPlayerControls, isPlaying: Bool)
    func seekBackwardPressed(playerControls: VideoPlayerControls)
    func fullscreenPressed(playerControls: VideoPlayerControls)
    func setPlayBackSpeed(playerControls: VideoPlayerControls, speed:OEXVideoSpeed)
    func sliderValueChanged(playerControls: VideoPlayerControls)
    func sliderTouchBegan(playerControls: VideoPlayerControls)
    func sliderTouchEnded(playerControls: VideoPlayerControls)
}

class VideoPlayerControls: UIView, VideoPlayerSettingsDelegate {
    
    var video : OEXHelperVideoDownload? {
        didSet {
            startBufferedTimer()
        }
    }
    private var playerSettings : OEXVideoPlayerSettings = OEXVideoPlayerSettings()
    private var isControlsHidden: Bool = true
    private var subtitleActivated : Bool = false
    private var bufferedTimer: Timer?
    private var dataInterface = OEXInterface.shared()
    private let videoPlayerController: VideoPlayer
    var delegate : VideoPlayerControlsDelegate?
    private let previousButtonSize = CGSize(width: 42.0, height: 42.0)
    private let rewindButtonSize = CGSize(width: 42.0, height: 42.0)
    private let durationSliderHeight: CGFloat = 34.0
    private let timeRemainingLabelSize = CGSize(width: 75.0, height: 34.0)
    private let settingButtonSize = CGSize(width: 24.0, height: 24.0)
    private let fullScreenButtonSize = CGSize(width: 20.0, height: 20.0)
    private let tableSettingSize = CGSize(width: 110.0, height: 100.0)
    private let nextButtonSizeSize = CGSize(width: 42.0, height: 42.0)
    
    lazy private var subTitleLabel : UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 31.0/255.0, green: 33.0/255.0, blue: 36.0/255.0, alpha: 0.4)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.layer.cornerRadius = 5
        label.layer.rasterizationScale = UIScreen.main.scale
        label.textAlignment = .center
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
    
    lazy private var rewindButton: CustomPlayerButton = {
        let button = CustomPlayerButton()
        button.setImage(UIImage.RewindIcon(), for: .normal)
        button.tintColor = .white
        button.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.delegate?.seekBackwardPressed(playerControls: weakSelf)
            }
        }, for: .touchUpInside)
        return button
    }()
    
    lazy private var durationSlider: CustomSlider = {
        let slider = CustomSlider()
        slider.isContinuous = true
        slider.setThumbImage(UIImage(named: "ic_seek_thumb.png"), for: .normal)
        slider.setMinimumTrackImage(UIImage(named: "ic_progressbar.png"), for: .normal)
        slider.secondaryTrackColor = UIColor(red: 76.0/255.0, green: 135.0/255.0, blue: 130.0/255.0, alpha: 0.9)
        slider.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.delegate?.sliderValueChanged(playerControls: weakSelf)
            }
        }, for: .valueChanged)
        slider.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.delegate?.sliderTouchBegan(playerControls: weakSelf)
            }
        }, for: .touchDown)
        slider.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.delegate?.sliderTouchEnded(playerControls: weakSelf)
            }
        }, for: .touchUpInside)
        slider.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.delegate?.sliderTouchEnded(playerControls: weakSelf)
            }
        }, for: .touchUpOutside)
        
        return slider
    }()
    
    lazy private var btnSettings: CustomPlayerButton = {
        let button = CustomPlayerButton()
        button.setImage(UIImage.SettingsIcon(), for: .normal)
        button.tintColor = .white
        button.oex_addAction({[weak self] (action) in
            self?.settingsButtonClicked()
        }, for: .touchUpInside)
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
        button.oex_addAction({[weak self] (action) in
                if let weakSelf = self {
                    button.isSelected = !button.isSelected
                    weakSelf.delegate?.playPausePressed(playerControls: weakSelf, isPlaying: button.isSelected)
                    weakSelf.autoHide()
                }
            }, for: .touchUpInside)
        return button
    }()
    
    lazy private var btnNext: CustomPlayerButton = {
        let button = CustomPlayerButton()
        button.setImage(UIImage(named: "ic_next"), for: .normal)
        button.setImage(UIImage(named: "ic_next_press"), for: .highlighted)
        button.oex_addAction({[weak self] (action) in
            self?.nextButtonClicked()
        }, for: .touchUpInside)
        return button
    }()
    
    lazy private var btnPrevious: CustomPlayerButton = {
        let button = CustomPlayerButton()
        button.setImage(UIImage(named: "ic_previous"), for: .normal)
        button.setImage(UIImage(named: "ic_previous_press"), for: .highlighted)
        button.oex_addAction({[weak self] (action) in
            self?.previousButtonClicked()
        }, for: .touchUpInside)
        return button
    }()
    
    lazy private var fullScreenButton: CustomPlayerButton = {
        let button = CustomPlayerButton()
        button.setImage(UIImage.ExpandIcon(), for: .normal)
        button.tintColor = .white
        button.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.autoHide()
                weakSelf.delegate?.fullscreenPressed(playerControls: weakSelf)
            }
        }, for: .touchUpInside)
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
    
    init(with player: VideoPlayer) {
        videoPlayerController = player
        super.init(frame: CGRect.zero)
        playerSettings.delegate = self
        backgroundColor = .clear
        addSubviews()
        setConstraints()
        setPlayerControlAccessibilityID()
        hideAndShowControls(isHidden: isControlsHidden)
        showHideNextPrevious(isHidden: true)
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
        addSubview(tapButton)
        addSubview(btnNext)
        addSubview(btnPrevious)
        addSubview(playPauseButton)
        addSubview(subTitleLabel)
        addSubview(tableSettings)
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
            make.height.equalTo(StandardFooterHeight)
        }
        
        rewindButton.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin)
            make.height.equalTo(rewindButtonSize.height)
            make.width.equalTo(rewindButtonSize.width)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        durationSlider.snp_makeConstraints { make in
            make.leading.equalTo(rewindButton.snp_trailing).offset(StandardVerticalMargin)
            make.height.equalTo(durationSliderHeight)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        timeRemainingLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        timeRemainingLabel.snp_makeConstraints { make in
            make.leading.equalTo(durationSlider.snp_trailing).offset(StandardVerticalMargin)
            make.centerY.equalTo(bottomBar.snp_centerY)
            make.width.equalTo(timeRemainingLabelSize.width)
            make.height.equalTo(timeRemainingLabelSize.height)
        }
        
        btnSettings.snp_makeConstraints { make in
            make.leading.equalTo(timeRemainingLabel.snp_trailing).offset(StandardVerticalMargin)
            make.height.equalTo(settingButtonSize.height)
            make.width.equalTo(settingButtonSize.width)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        fullScreenButton.snp_makeConstraints { make in
            make.leading.equalTo(btnSettings.snp_trailing).offset(StandardVerticalMargin)
            make.height.equalTo(fullScreenButtonSize.height)
            make.width.equalTo(fullScreenButtonSize.width)
            make.trailing.equalTo(self).inset(StandardVerticalMargin)
            make.centerY.equalTo(bottomBar.snp_centerY)
        }
        
        tableSettings.snp_makeConstraints { make in
            make.height.equalTo(tableSettingSize.height)
            make.width.equalTo(tableSettingSize.width)
            make.bottom.equalTo(btnSettings.snp_top).offset(-StandardVerticalMargin)
            make.centerX.equalTo(btnSettings.snp_centerX).offset(-StandardFooterHeight)
        }
        
        tapButton.snp_makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(bottomBar.snp_top)
        }
        
        btnPrevious.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin)
            make.height.equalTo(previousButtonSize.height)
            make.width.equalTo(previousButtonSize.width)
            make.centerY.equalTo(self.snp_centerY)
        }
        
        playPauseButton.snp_makeConstraints { make in
            make.center.equalTo(self.snp_center)
        }
        
        btnNext.snp_makeConstraints { make in
            make.height.equalTo(nextButtonSizeSize.height)
            make.width.equalTo(nextButtonSizeSize.width)
            make.trailing.equalTo(self).inset(StandardVerticalMargin)
            make.centerY.equalTo(self.snp_centerY)
        }
        
        subTitleLabel.snp_makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp_top).offset(StandardHorizontalMargin*2)
            make.centerX.equalTo(snp_centerX)
            make.leadingMargin.greaterThanOrEqualTo(StandardVerticalMargin*2)
            make.trailingMargin.lessThanOrEqualTo(StandardVerticalMargin*2)
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
    
    @objc func autoHide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(hideAndShowControls(isHidden:)), with: 1, afterDelay: 3.0)
    }
    
    @objc func hideAndShowControls(isHidden: Bool) {
        isControlsHidden = isHidden
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
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
        }, completion: {[weak self] _ in
            self?.updateSubtTitleConstraints()
        })
    }
    
    func updateTimeLabel(elapsedTime: Float64, duration: Float64) {
        let totalTime: Float64 = CMTimeGetSeconds(videoPlayerController.duration)
        timeRemainingLabel.text = String(format: "%02d:%02d / %02d:%02d", ((lround(elapsedTime) / 60) % 60), lround(elapsedTime) % 60, ((lround(totalTime) / 60) % 60), lround(totalTime) % 60)
        if subtitleActivated {
            subTitleLabel.text = videoPlayerController.subTitle(at: elapsedTime)
        }
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
    
    private func settingsButtonClicked() {
        NSObject.cancelPreviousPerformRequests(withTarget:self)
        tableSettings.isHidden = !tableSettings.isHidden
    }
    
    func showSubSettings(chooser: UIAlertController) {
        let controller = firstAvailableUIViewController()
        
        chooser.configurePresentationController(withSourceView: btnSettings)
        controller?.present(chooser, animated: true, completion: nil)
    }
    
    func setCaption(language: String) {
        OEXInterface.setCCSelectedLanguage(language)
        if language == "" {
            deAvtivateSubTitles()
        }
        else {
            activateSubTitles()
            if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
                OEXAnalytics.shared().trackTranscriptLanguage(videoId, currentTime: videoPlayerController.currentTime, language: language, courseID: courseId, unitURL: unitUrl)
            }
        }
    }
    
    func setPlaybackSpeed(speed: OEXVideoSpeed) {
        delegate?.setPlayBackSpeed(playerControls: self, speed: speed)
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
    
    func showHideNextPrevious(isHidden: Bool) {
        btnNext.isHidden = isHidden
        btnNext.isEnabled = !isHidden
        btnPrevious.isHidden = isHidden
        btnPrevious.isEnabled = !isHidden
    }
    
   func nextButtonClicked() {
        autoHide()
        dataInterface.selectedCCIndex = -1;
        dataInterface.selectedVideoSpeedIndex = -1;
        videoPlayerController.resetPlayerView()
        NotificationCenter.default.post(name: Notification.Name(rawValue:NOTIFICATION_VIDEO_PLAYER_NEXT), object: self)
    }
    
   func previousButtonClicked() {
        autoHide()
        dataInterface.selectedCCIndex = -1;
        dataInterface.selectedVideoSpeedIndex = -1;
        videoPlayerController.resetPlayerView()
        NotificationCenter.default.post(name: Notification.Name(rawValue:NOTIFICATION_VIDEO_PLAYER_PREVIOUS), object: self)
    }
}
