//
//  VideoPlayerControls.swift
//  edX
//
//  Created by Salman on 06/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import CoreMedia

protocol VideoPlayerControlsDelegate: class {
    func playPausePressed(playerControls: VideoPlayerControls, isPlaying: Bool)
    func seekBackwardPressed(playerControls: VideoPlayerControls)
    func fullscreenPressed(playerControls: VideoPlayerControls)
    func setPlayBackSpeed(playerControls: VideoPlayerControls, speed:OEXVideoSpeed)
    func sliderValueChanged(playerControls: VideoPlayerControls)
    func sliderTouchBegan(playerControls: VideoPlayerControls)
    func sliderTouchEnded(playerControls: VideoPlayerControls)
    func captionUpdate(playerControls: VideoPlayerControls, language: String)
}

class VideoPlayerControls: UIView, VideoPlayerSettingsDelegate {
    
    typealias Environment = OEXInterfaceProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    private let environment : Environment
    fileprivate var settings = VideoPlayerSettings()
    private var isControlsHidden = true
    fileprivate var subtitleActivated = false
    private var bufferedTimer: Timer?
    weak private var videoPlayer: VideoPlayer?
    weak var delegate : VideoPlayerControlsDelegate?
    private let previousButtonSize = CGSize(width: 42.0, height: 42.0)
    private let rewindButtonSize = CGSize(width: 42.0, height: 42.0)
    private let durationSliderHeight: CGFloat = 34.0
    private let timeRemainingLabelSize = CGSize(width: 75.0, height: 34.0)
    private let settingButtonSize = CGSize(width: 24.0, height: 24.0)
    private let fullScreenButtonSize = CGSize(width: 20.0, height: 20.0)
    private let tableSettingSize = CGSize(width: 110.0, height: 100.0)
    private let nextButtonSize = CGSize(width: 42.0, height: 42.0)
    
    var video : OEXHelperVideoDownload? {
        didSet {
            startBufferedTimer()
            settings.optionsTable.reloadData()
        }
    }
    
    lazy private var subTitleLabel : UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 31.0/255.0, green: 33.0/255.0, blue: 36.0/255.0, alpha: 0.4)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.layer.cornerRadius = 5
        label.layer.rasterizationScale = UIScreen.main.scale
        label.textAlignment = .center
        label.font = self.environment.styles.sansSerif(ofSize: 12)
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
        let tableView = self.settings.optionsTable
        tableView.isHidden = true
        self.settings.delegate = self
        return tableView
    }()
    
    lazy private var playPauseButton : AccessibilityCLButton = {
        let button = AccessibilityCLButton()
        button.setAttributedTitle(title: UIImage.PauseTitle(), forState: .normal, animated: true)
        button.setAttributedTitle(title: UIImage.PlayTitle(), forState: .selected, animated: true)
        button.oex_addAction({[weak self] (action) in
            if let weakSelf = self {
                weakSelf.tableSettings.isHidden = true
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
        label.font = self.environment.styles.semiBoldSansSerif(ofSize: 12.0)
        return label
    }()
    
    lazy private var videoTitleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.font = self.environment.styles.semiBoldSansSerif(ofSize: 16.0)
        label.textAlignment = .left
        label.textColor = .white
        label.text = Strings.untitled
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 1
        label.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        label.layer.shadowOpacity = 0.8
        label.text = self.videoPlayer?.videoTitle
        return label
    }()
    
    private var barColor: UIColor {
        return UIColor.black.withAlphaComponent(0.7)
    }
    
    init(environment : Environment, player: VideoPlayer) {
        self.environment = environment
        videoPlayer = player
        super.init(frame: CGRect.zero)
        settings.delegate = self
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
        if bufferedTimer?.isValid ?? false {
            bufferedTimer?.invalidate()
            bufferedTimer = nil
        }
    }
    
    private func setConstraints() {
        topBar.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(StandardFooterHeight)
        }
        
        videoTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(topBar.snp.leading).offset(StandardVerticalMargin)
            make.height.equalTo(rewindButtonSize.height)
            make.centerY.equalTo(topBar.snp.centerY)
        }
        
        bottomBar.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.bottom.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(StandardFooterHeight)
        }
        
        rewindButton.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin)
            make.height.equalTo(rewindButtonSize.height)
            make.width.equalTo(rewindButtonSize.width)
            make.centerY.equalTo(bottomBar.snp.centerY)
        }
        
        durationSlider.snp.makeConstraints { make in
            make.leading.equalTo(rewindButton.snp.trailing).offset(StandardVerticalMargin)
            make.height.equalTo(durationSliderHeight)
            make.centerY.equalTo(bottomBar.snp.centerY)
        }
        
        timeRemainingLabel.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        timeRemainingLabel.snp.makeConstraints { make in
            make.leading.equalTo(durationSlider.snp.trailing).offset(StandardVerticalMargin)
            make.centerY.equalTo(bottomBar.snp.centerY)
            make.width.equalTo(timeRemainingLabelSize.width)
            make.height.equalTo(timeRemainingLabelSize.height)
        }
        
        btnSettings.snp.makeConstraints { make in
            make.leading.equalTo(timeRemainingLabel.snp.trailing).offset(StandardVerticalMargin)
            make.height.equalTo(settingButtonSize.height)
            make.width.equalTo(settingButtonSize.width)
            make.centerY.equalTo(bottomBar.snp.centerY)
        }
        
        fullScreenButton.snp.makeConstraints { make in
            make.leading.equalTo(btnSettings.snp.trailing).offset(StandardVerticalMargin)
            make.height.equalTo(fullScreenButtonSize.height)
            make.width.equalTo(fullScreenButtonSize.width)
            make.trailing.equalTo(self).inset(StandardVerticalMargin)
            make.centerY.equalTo(bottomBar.snp.centerY)
        }
        
        tableSettings.snp.makeConstraints { make in
            make.height.equalTo(tableSettingSize.height)
            make.width.equalTo(tableSettingSize.width)
            make.bottom.equalTo(btnSettings.snp.top).offset(-StandardVerticalMargin)
            make.centerX.equalTo(btnSettings.snp.centerX).offset(-StandardFooterHeight)
        }
        
        tapButton.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        btnPrevious.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin)
            make.height.equalTo(previousButtonSize.height)
            make.width.equalTo(previousButtonSize.width)
            make.centerY.equalTo(self.snp.centerY)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.center.equalTo(self.snp.center)
        }
        
        btnNext.snp.makeConstraints { make in
            make.height.equalTo(nextButtonSize.height)
            make.width.equalTo(nextButtonSize.width)
            make.trailing.equalTo(self).inset(StandardVerticalMargin)
            make.centerY.equalTo(self.snp.centerY)
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(bottomBar.snp.top).offset(StandardHorizontalMargin*2)
            make.centerX.equalTo(snp.centerX)
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
        playPauseButton.setAccessibilityLabelsForStateNormal(normalStateLabel: Strings.accessibilityPause, selectedStateLabel: Strings.accessibilityPlay)
        tapButton.isAccessibilityElement = false
    }
    
    private func updateSubtTitleConstraints() {
        subTitleLabel.snp.updateConstraints { make in
            let bottomOffset = isControlsHidden ? 30 : -StandardVerticalMargin
            make.bottom.equalTo(bottomBar.snp.top).offset(bottomOffset)
        }
    }
    
    func setPlayPauseButtonState(isSelected: Bool) {
        playPauseButton.isSelected = isSelected
    }
    
    @objc func autoHide() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if !UIAccessibilityIsVoiceOverRunning() {
            perform(#selector(hideAndShowControls(isHidden:)), with: 1, afterDelay: 3.0)
        }
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
            else {
                self?.tableSettings.isHidden = true
            }
            }, completion: { [weak self] _ in
                self?.updateSubtTitleConstraints()
        })
    }
    
    func updateTimeLabel(elapsedTime: Float64, duration: Float64) {
        guard let duration = videoPlayer?.duration else { return }
        let totalTime: Float64 = CMTimeGetSeconds (duration)
        
        timeRemainingLabel.text = String(format: "%02d:%02d / %02d:%02d", ((lround(elapsedTime) / 60) % 60), lround(elapsedTime) % 60, ((lround(totalTime) / 60) % 60), lround(totalTime) % 60)
        if subtitleActivated {
            subTitleLabel.text = videoPlayer?.subTitle(at: elapsedTime).decodingHTMLEntities
        }
    }
    
    func updateFullScreenButtonImage() {
        if videoPlayer?.isFullScreen ?? false {
            fullScreenButton.setImage(UIImage.ShrinkIcon(), for: .normal)
            fullScreenButton.accessibilityLabel = Strings.accessibilityExitFullscreen
        }
        else {
            fullScreenButton.setImage(UIImage.ExpandIcon(), for: .normal)
            fullScreenButton.accessibilityLabel = Strings.accessibilityFullscreen
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
        tableSettings.isHidden = true
        let controller = firstAvailableUIViewController()
        
        chooser.configurePresentationController(withSourceView: btnSettings)
        controller?.present(chooser, animated: true, completion: nil)
    }
    
    func setCaption(language: String) {
        delegate?.captionUpdate(playerControls: self, language: language)
    }
    
    func setPlaybackSpeed(speed: OEXVideoSpeed) {
        setPlayPauseButtonState(isSelected: false)
        delegate?.setPlayBackSpeed(playerControls: self, speed: speed)
    }
    
    //MARK Video player setting delegate method
    func videoInfo() -> OEXVideoSummary? {
        return video?.summary
    }
    
    func activateSubTitles() {
        showSubTitles(show: true)
        environment.analytics.trackShowTranscript(video?.summary?.videoID ?? "", currentTime: videoPlayer?.currentTime ?? 0.0, courseID: video?.course_id ?? "", unitURL: video?.summary?.unitURL ?? "")
    }
    
    func deAvtivateSubTitles() {
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackHideTranscript(videoId, currentTime: videoPlayer?.currentTime ?? 0.0, courseID: courseId, unitURL: unitUrl)
        }
        environment.interface?.selectedCCIndex = -1
        subTitleLabel.text = ""
        showSubTitles(show: false)
    }
    
    private func showSubTitles(show: Bool) {
        subTitleLabel.isHidden = !show
        subtitleActivated = show
    }
    
    @objc private func monitorBufferedMovie() {
        let secondaryProgress = floor(videoPlayer?.playableDuration ?? 0.0)
        let totalTime = floor(videoPlayer?.duration.seconds ?? 0.0)
        let time = secondaryProgress/totalTime
        if time.isNaN {
            if !(videoPlayer?.isPlaying ?? true) {
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
        topBar.isHidden = isHidden
    }
    
    func nextButtonClicked() {
        changeBlock(with: NOTIFICATION_VIDEO_PLAYER_NEXT)
    }
    
    func previousButtonClicked() {
        changeBlock(with: NOTIFICATION_VIDEO_PLAYER_PREVIOUS)
    }
    
    private func changeBlock(with name: String) {
        autoHide()
        environment.interface?.selectedCCIndex = -1;
        environment.interface?.selectedVideoSpeedIndex = -1;
        NotificationCenter.default.post(name: Notification.Name(rawValue:name), object: self)
    }
    
    func reset() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        stopBufferedTimer()
    }
}

// Specific for test cases
extension VideoPlayerControls {
    
    var t_playerSettings: VideoPlayerSettings {
        return settings
    }
    
    var t_subtitleActivated: Bool {
        return subtitleActivated
    }
}
