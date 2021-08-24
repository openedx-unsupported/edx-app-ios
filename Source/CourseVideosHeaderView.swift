//
//  CourseVideosHeaderView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 16/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol CourseVideosHeaderViewDelegate: AnyObject {
    func courseVideosHeaderViewTapped()
    func invalidOrNoNetworkFound()
    func didTapVideoQuality()
}

// To remove specific observers we need reference of notification and observer as well.
fileprivate struct NotificationObserver {
    var notification: NSNotification.Name
    var observer: Removable
}

class CourseVideosHeaderView: UIView {
    
    typealias Environment =  OEXInterfaceProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    static var height: CGFloat = 72
    // We need to execute deletion (on turn off switch) after some delay to avoid accidental deletion.
    private let toggleActionDelay: Double = 4 // In seconds
    private let imageSize: CGFloat = 20
    private let bulkDownloadHelper: BulkDownloadHelper
    private var toggleAction: DispatchWorkItem?
    private var observers: [NotificationObserver] = []
    private let environment: Environment
    weak var delegate: CourseVideosHeaderViewDelegate?
    private var blockID: CourseBlockID?
    
    // MARK: - UI Properties -
    private lazy var topContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseVideosHeader:top-container-view"
        return view
    }()
    
    private lazy var bottomContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseVideosHeader:bottom-container-view"
        return view
    }()
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = environment.styles.neutralDark()
        view.accessibilityIdentifier = "CourseVideosHeader:seperator-view"
        return view
    }()
    
    lazy private var videoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseVideosHeader:image-view"
        imageView.isAccessibilityElement = false
        imageView.tintColor = environment.styles.primaryBaseColor()
        imageView.image = Icon.CourseVideos.imageWithFontSize(size: imageSize)
        return imageView
    }()
    
    private let spinner: SpinnerView = {
        let spinner = SpinnerView(size: .medium, color: .primary)
        spinner.accessibilityIdentifier = "CourseVideosHeader:spinner"
        spinner.isAccessibilityElement = false
        return spinner
    }()
    
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeader:title-label"
        label.isAccessibilityElement = false
        return label
    }()
    
    lazy private var subTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeader:subtitle-label"
        label.isAccessibilityElement = false
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()
    
    lazy private var showDownloadsButton: UIButton = {
        let button =  UIButton()
        button.accessibilityIdentifier = "CourseVideosHeader:show-downloads-button"
        button.accessibilityHint = Strings.Accessibility.showCurrentDownloadsButtonHint
        button.accessibilityTraits = UIAccessibilityTraits(rawValue: UIAccessibilityTraits.button.rawValue | UIAccessibilityTraits.updatesFrequently.rawValue)
        button.oex_addAction({
            [weak self] _ in
            if self?.state == .downloading {
                self?.delegate?.courseVideosHeaderViewTapped()
            }
        }, for: .touchUpInside)
        return button
    }()
    
    lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.accessibilityIdentifier = "CourseVideosHeader:toggle-switch"
        toggleSwitch.onTintColor = environment.styles.primaryBaseColor()
        toggleSwitch.tintColor = environment.styles.neutralLight()
        toggleSwitch.oex_addAction({[weak self] _ in
            self?.switchToggled()
        }, for: .valueChanged)
        return toggleSwitch
    }()
    
    lazy private var downloadProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.accessibilityIdentifier = "CourseVideosHeader:download-progress-view"
        progressView.isAccessibilityElement = false
        progressView.tintColor = environment.styles.successBase()
        progressView.trackTintColor = environment.styles.neutralXLight()
        return progressView
    }()
    
    private lazy var settingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Settings.imageWithFontSize(size: imageSize)
        imageView.tintColor = environment.styles.primaryBaseColor()
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier = "CourseVideosHeader:setting-image-view"
        return imageView
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.ChevronRight.imageWithFontSize(size: imageSize + (imageSize / 2))
        imageView.tintColor = environment.styles.primaryBaseColor()
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier = "CourseVideosHeader:chevron-image-view"
        return imageView
    }()
    
    private lazy var bottomTitleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleLabelStyle.attributedString(withText: Strings.VideoDownloadQuality.title)
        label.accessibilityIdentifier = "CourseVideosHeader:bottom-title-view"
        return label
    }()
    
    private lazy var bottomSubtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeader:bottom-subtitle-view"
        label.attributedText = subTitleLabelStyle.attributedString(withText: environment.interface?.getVideoDownladQuality().title)
        return label
    }()
    
    private lazy var videoQualityButton: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapVideoQuality()
        }, for: .touchUpInside)
        button.accessibilityIdentifier = "CourseVideosHeader:video-quality-button"
        return button
    }()
    
    // MARK: - Styles -
    private var titleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: environment.styles.primaryBaseColor())
    }
    private var subTitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .light, size: .base, color : environment.styles.primaryXLightColor())
    }
    
    // MARK: - Properties -
    private var toggledOn: Bool {
        return state == .downloading || state == .downloaded
    }
    
    private var title: String {
        switch state {
        case .downloaded:
            return Strings.allVideosDownloadedTitle
        case .downloading:
            return Strings.downloadingVideosTitle
        default:
            return Strings.downloadToDeviceTitle
        }
    }
    
    private var videoSizeForSubTitle: Double {
        return (state == .downloaded ? bulkDownloadHelper.totalSize : bulkDownloadHelper.totalSize - bulkDownloadHelper.downloadedSize).roundedMB
    }
    
    private var subTitle: String {
        switch state {
        case .partial:
            return Strings.bulkDownloadVideosSubTitle(count: "\(bulkDownloadHelper.partialAndNewVideosCount)", videosSize: "\(videoSizeForSubTitle)")(bulkDownloadHelper.partialAndNewVideosCount)
        case .downloading:
            return Strings.allDownloadingVideosSubTitle(remainingVideosCount: "\(bulkDownloadHelper.partialAndNewVideosCount)", remainingVideosSize: "\(videoSizeForSubTitle)")
        default:
            return Strings.bulkDownloadVideosSubTitle(count: "\(videos.count)", videosSize: "\(videoSizeForSubTitle)")(videos.count)
        }
    }
    
    private var switchAccessibilityLabel: String {
        let title = state == .downloading ? Strings.Accessibility.downloadingVideosTitle : titleLabel.attributedText?.string ?? ""
        let subTitle = subTitleLabel.attributedText?.string ?? ""
        return "\(title), \(subTitle)"
    }
    
    private var switchAccessibilityHint: String {
        switch state {
        case .new:
            return Strings.Accessibility.bulkDownloadHint
        case .downloaded:
            return Strings.Accessibility.bulkDownloadDownloadedHint
        default:
            return Strings.Accessibility.bulkDownloadDownloadingHint
        }
    }
    
    private var state: BulkDownloadState {
        return bulkDownloadHelper.state
    }
    
    var videos: [OEXHelperVideoDownload] {
        get {
            return bulkDownloadHelper.videos
        }
        set {
            bulkDownloadHelper.videos = newValue
        }
    }
    
    // MARK: - Initializers -
    init(with course: OEXCourse, environment: Environment, videos: [OEXHelperVideoDownload]?, blockID: CourseBlockID?) {
        self.environment = environment
        self.blockID = blockID
        bulkDownloadHelper = BulkDownloadHelper(with: course, videos: videos ?? [])
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods -
    func addObservers() {
        for notification in [
            NSNotification.Name.OEXDownloadStarted,
            NSNotification.Name.OEXDownloadEnded,
            NSNotification.Name.OEXDownloadDeleted,
        ] {
            addObserver(notification: notification)
        }
    }
    
    func removeObservers() {
        for notificationObserver in observers {
            removeObserver(notificationObserver: notificationObserver)
        }
        observers.removeAll()
    }
    
    fileprivate func addObserver(notification: Notification.Name) {
        let observer = NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (notification, observer, _) -> Void in
            observer.refreshView()
        }
        let notificationObserver = NotificationObserver(notification: notification, observer: observer)
        observers.append(notificationObserver)
    }
    
    fileprivate func removeObserver(notificationObserver: NotificationObserver) {
        notificationObserver.observer.remove()
        NotificationCenter.default.removeObserver(self, name: notificationObserver.notification, object: nil)
    }
    
    fileprivate func videoDownloadProgressChangeObserver() {
        let progressChangedNotification = NSNotification.Name.OEXDownloadProgressChanged
        if state == .downloading {
            let alreadyAdded = observers.reduce(false) {(acc, observer) in
                return acc || observer.notification == progressChangedNotification
            }
            if !alreadyAdded {
                addObserver(notification: progressChangedNotification)
            }
        }
        else {
            for notificationObserver in observers {
                if notificationObserver.notification == progressChangedNotification {
                    removeObserver(notificationObserver: notificationObserver)
                }
            }
            observers = observers.filter { $0.notification != progressChangedNotification }
        }
    }
    
    func refreshView() {
        guard toggleAction == nil else { return }
        bulkDownloadHelper.refreshState()
        toggleSwitch.isOn = toggledOn
        downloadProgressView.isHidden = state != .downloading
        spinner.isHidden = state != .downloading
        videoImageView.isHidden = state == .downloading
        titleLabel.attributedText = titleLabelStyle.attributedString(withText: title)
        subTitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: subTitle)
        bottomSubtitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: environment.interface?.getVideoDownladQuality().title)
        downloadProgressView.setProgress(bulkDownloadHelper.progress, animated: true)
        showDownloadsButton.isAccessibilityElement = state == .downloading
        toggleSwitch.accessibilityLabel = switchAccessibilityLabel
        toggleSwitch.accessibilityHint = switchAccessibilityHint
        videoDownloadProgressChangeObserver()
    }
    
    private func switchToggled() {
        toggleAction?.cancel()
        if toggleSwitch.isOn {
            if (environment.interface?.canDownload() ?? false) {
                toggleAction = DispatchWorkItem { [weak self] in self?.startDownloading() }
                if let task = toggleAction {
                    DispatchQueue.main.async(execute: task)
                }
            }
            else {
                toggleSwitch.isOn = false
                delegate?.invalidOrNoNetworkFound()
            }
        }
        else {
            toggleAction = DispatchWorkItem { [weak self] in self?.stopAndDeleteDownloads() }
            if let task = toggleAction {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + toggleActionDelay, execute: task)
            }
            environment.analytics.trackBulkDownloadToggle(isOn: toggleSwitch.isOn, courseID: bulkDownloadHelper.course.course_id ?? "", totalVideosCount: videos.count, remainingVideosCount: bulkDownloadHelper.newVideosCount, blockID: blockID)
        }
        
    }
    
    private func startDownloading() {
        environment.interface?.downloadVideos(videos) {
            [weak self] cancelled in
            self?.toggleAction = nil
            // User turn on switch for course which has large download, but after watching warning cancel the bulk download, for this we need to update headerview accordingly
            if cancelled {
                self?.refreshView()
            }
            else {
                if let owner = self {
                    owner.environment.analytics.trackBulkDownloadToggle(isOn: owner.toggleSwitch.isOn, courseID: owner.bulkDownloadHelper.course.course_id ?? "", totalVideosCount: owner.videos.count, remainingVideosCount: owner.bulkDownloadHelper.newVideosCount, blockID: owner.blockID)
                }
            }
        }
    }
    
    private func stopAndDeleteDownloads() {
        environment.interface?.deleteDownloadedVideos(videos) { [weak self] _ in
            self?.toggleAction = nil
            self?.refreshView()
        }
    }
    
    private func configureView() {
        accessibilityIdentifier = "CourseVideosHeader: view"
        backgroundColor = environment.styles.neutralXLight()
        addSubviews()
        accessibilityElements = [toggleSwitch, showDownloadsButton]
    }
    
    private func addSubviews() {
        topContainer.addSubview(videoImageView)
        topContainer.addSubview(spinner)
        topContainer.addSubview(titleLabel)
        topContainer.addSubview(subTitleLabel)
        topContainer.addSubview(showDownloadsButton)
        topContainer.addSubview(toggleSwitch)
        topContainer.addSubview(downloadProgressView)
        
        addSubview(topContainer)
        addSubview(separator)
        
        bottomContainer.addSubview(bottomTitleLabel)
        bottomContainer.addSubview(bottomSubtitleLabel)
        bottomContainer.addSubview(settingImageView)
        bottomContainer.addSubview(chevronImageView)
        bottomContainer.addSubview(videoQualityButton)
        
        videoQualityButton.superview?.bringSubviewToFront(videoQualityButton)
        
        addSubview(bottomContainer)
                
        setConstraints()
    }
    
    private func setConstraints() {
        topContainer.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(separator.snp.top)
            make.height.equalTo(CourseVideosHeaderView.height)
        }
        
        videoImageView.snp.makeConstraints { make in
            make.leading.equalTo(topContainer).offset(StandardHorizontalMargin)
            make.centerY.equalTo(topContainer)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        spinner.snp.makeConstraints { make in
            make.edges.equalTo(videoImageView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(videoImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(toggleSwitch.snp.leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(topContainer.snp.centerY).inset(StandardVerticalMargin / 2)
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(topContainer.snp.centerY).offset(StandardVerticalMargin / 2)
        }
        
        showDownloadsButton.snp.makeConstraints { make in
            make.edges.equalTo(topContainer)
        }
        
        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalTo(topContainer).inset(StandardHorizontalMargin)
            make.centerY.equalTo(topContainer)
        }
        
        downloadProgressView.snp.makeConstraints { make in
            make.leading.equalTo(topContainer)
            make.trailing.equalTo(topContainer)
            make.bottom.equalTo(topContainer)
            make.height.equalTo(2)
        }
        
        separator.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(bottomContainer.snp.top)
            make.height.equalTo(1)
        }
        
        bottomContainer.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(CourseVideosHeaderView.height)
        }
        
        settingImageView.snp.makeConstraints { make in
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin)
            make.centerY.equalTo(bottomContainer)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin)
            make.centerY.equalTo(bottomContainer)
            make.height.equalTo(imageSize + (imageSize / 2))
            make.width.equalTo(imageSize + (imageSize / 2))
        }
        
        bottomTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(settingImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(chevronImageView.snp.leading).inset(StandardHorizontalMargin)
            make.bottom.equalTo(bottomContainer.snp.centerY).inset(StandardVerticalMargin / 2)
        }
        
        bottomSubtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(bottomTitleLabel)
            make.trailing.equalTo(bottomTitleLabel)
            make.top.equalTo(bottomContainer.snp.centerY).offset(StandardVerticalMargin / 2)
        }
        
        videoQualityButton.snp.makeConstraints { make in
            make.edges.equalTo(bottomContainer)
        }
    }
}
