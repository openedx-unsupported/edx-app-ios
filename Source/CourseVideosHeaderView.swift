//
//  CourseVideosHeaderView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 16/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol CourseVideosHeaderViewDelegate: class {
    func courseVideosHeaderViewTapped()
    func invalidOrNoNetworkFound()
}

// To remove specific observers we need reference of notification and observer as well.
fileprivate struct NotificationObserver {
    var notification: NSNotification.Name
    var observer: Removable
}

class CourseVideosHeaderView: UIView {
    
    typealias Environment =  OEXInterfaceProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    static var height: CGFloat = 72.0
    // We need to execute deletion (on turn off switch) after some delay to avoid accidental deletion.
    private let toggleActionDelay = 4.0 // In seconds
    private let bulkDownloadHelper: BulkDownloadHelper
    private var toggleAction: DispatchWorkItem?
    private var observers:[NotificationObserver] = []
    private let environment: Environment
    weak var delegate: CourseVideosHeaderViewDelegate?
    private var blockID: CourseBlockID?
    
    // MARK: - UI Properties -
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "CourseVideosHeaderView:image-view"
        imageView.isAccessibilityElement = false
        imageView.tintColor = self.environment.styles.primaryBaseColor()
        return imageView
    }()
    private let spinner: SpinnerView = {
        let spinner = SpinnerView(size: .Medium, color: .Primary)
        spinner.accessibilityIdentifier = "CourseVideosHeaderView:spinner"
        spinner.isAccessibilityElement = false
        return spinner
    }()
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeaderView:title-label"
        label.isAccessibilityElement = false
        return label
    }()
    lazy private var subTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeaderView:sub-title-label"
        label.isAccessibilityElement = false
        return label
    }()
    lazy private var showDownloadsButton: UIButton = {
        let button =  UIButton()
        button.accessibilityIdentifier = "CourseVideosHeaderView:show-downloads-button"
        button.accessibilityHint = Strings.Accessibility.showCurrentDownloadsButtonHint
        button.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently
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
        toggleSwitch.accessibilityIdentifier = "CourseVideosHeaderView:toggle-switch"
        toggleSwitch.onTintColor = self.environment.styles.utilitySuccessBase()
        toggleSwitch.tintColor = self.environment.styles.neutralLight()
        toggleSwitch.oex_addAction({[weak self] _ in
            self?.switchToggled()
        }, for: .valueChanged)
        return toggleSwitch
    }()
    lazy private var downloadProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.accessibilityIdentifier = "CourseVideosHeaderView:download-progress-view"
        progressView.isAccessibilityElement = false
        progressView.tintColor = self.environment.styles.utilitySuccessBase()
        progressView.trackTintColor = self.environment.styles.neutralXLight()
        return progressView
    }()
    
    // MARK: - Styles -
    private var titleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: environment.styles.primaryBaseColor())
    }
    private var subTitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : environment.styles.neutralDark())
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
        for notification in [NSNotification.Name.OEXDownloadStarted, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXDownloadDeleted] {
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
        imageView.isHidden = state == .downloading
        titleLabel.attributedText = titleLabelStyle.attributedString(withText: title)
        subTitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: subTitle)
        downloadProgressView.setProgress(bulkDownloadHelper.progress, animated: true)
        showDownloadsButton.isAccessibilityElement = state == .downloading
        toggleSwitch.accessibilityLabel = switchAccessibilityLabel
        toggleSwitch.accessibilityHint = switchAccessibilityHint
        videoDownloadProgressChangeObserver()
    }
    
    private func switchToggled(){
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
        backgroundColor = environment.styles.neutralXXLight()
        addSubviews()
        imageView.image = Icon.CourseVideos.imageWithFontSize(size: 20)
        accessibilityElements = [toggleSwitch, showDownloadsButton]
    }
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(spinner)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(showDownloadsButton)
        addSubview(toggleSwitch)
        addSubview(downloadProgressView)
        setConstraints()
    }
    
    private func setConstraints() {
        
        imageView.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.centerY.equalTo(snp.centerY)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        
        spinner.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(toggleSwitch.snp.leading).offset(-StandardHorizontalMargin)
            make.top.equalTo(self).offset(1.5 * StandardVerticalMargin)
        }
        
        subTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
        }
        
        showDownloadsButton.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.centerY.equalTo(snp.centerY)
        }
        
        downloadProgressView.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(2)
            make.top.equalTo(subTitleLabel.snp.bottom).offset(1.5 * StandardVerticalMargin)
        }
    }
    
}
