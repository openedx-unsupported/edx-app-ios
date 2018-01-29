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
}

// To remove specific observers we need reference of notification and observer as well.
fileprivate struct NotificationObserver {
    var notification: NSNotification.Name
    var observer: Removable
}

class CourseVideosHeaderView: UIView {
    
    static var height: CGFloat = 72.0
    // We need to execute deletion (on turn off switch) after some delay to avoid accidental deletion.
    private let toggleActionDelay = 5.0 // In Seconds
    private let bulkDownloadHelper: BulkDownloadHelper
    private var toggleAction: DispatchWorkItem?
    private var observers:[NotificationObserver] = []
    weak var delegate: CourseVideosHeaderViewDelegate?
    
    // MARK: - UI Properties -
    lazy private var imageView: UIImageView = {
        let image = UIImageView()
        image.accessibilityIdentifier = "CourseVideosHeaderView:image-view"
        return image
    }()
    private let spinner: SpinnerView = {
        let spinner = SpinnerView(size: .Medium, color: .Primary)
        spinner.accessibilityIdentifier = "CourseVideosHeaderView:spinner"
        return spinner
    }()
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeaderView:title-label"
        return label
    }()
    lazy private var subTitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseVideosHeaderView:sub-title-label"
        return label
    }()
    lazy private var showDownloadsButton: UIButton = {
        let button =  UIButton()
        button.accessibilityIdentifier = "CourseVideosHeaderView:show-downloads-button"
        button.accessibilityHint = Strings.accessibilityDownloadProgressButtonHint
        button.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently
        return button
    }()
    lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.accessibilityIdentifier = "CourseVideosHeaderView:toggle-switch"
        toggleSwitch.onTintColor = self.styles.utilitySuccessBase()
        toggleSwitch.tintColor = self.styles.neutralLight()
        toggleSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
//                owner.removeObservers()
                owner.switchToggled()
            }
            }, for: .valueChanged)
        return toggleSwitch
    }()
    lazy private var downloadProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.accessibilityIdentifier = "CourseVideosHeaderView:download-progress-view"
        progressView.tintColor = self.styles.utilitySuccessBase()
        progressView.trackTintColor = self.styles.neutralXLight()
        return progressView
    }()
    
    // MARK: - Styles -
    private var styles : OEXStyles {
        return OEXStyles.shared()
    }
    private var titleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: styles.primaryBaseColor())
    }
    private var subTitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : styles.neutralDark())
    }
    
    // MARK: - Properties -
    
    private var toggleOn: Bool {
        return bulkDownloadHelper.state == .downloading || bulkDownloadHelper.state == .downloaded
    }
    
    private var title: String {
        switch bulkDownloadHelper.state {
        case .downloaded:
            return Strings.allVideosDownloadedTitle
        case .downloading:
            return Strings.downloadingVideosTitle
        default:
            return Strings.downloadToDeviceTitle
        }
    }
    
    private var subTitle: String {
        switch bulkDownloadHelper.state {
        case .partial:
            return Strings.partialDownloadingVideosSubTitle(remainingVideosCount: "\(bulkDownloadHelper.partialAndNewVideosCount)", remainingVideosSize: "\(bulkDownloadHelper.videoSizeForStatus)")
        case .downloading:
            return Strings.partialDownloadingVideosSubTitle(remainingVideosCount: "\(bulkDownloadHelper.partialAndNewVideosCount)", remainingVideosSize: "\(bulkDownloadHelper.videoSizeForStatus)")
        default:
            return Strings.allVideosSubTitle(videosCount: "\(bulkDownloadHelper.courseVideos.count)", videosSize: "\(bulkDownloadHelper.videoSizeForStatus)")
        }
    }
    
    private var toggleAccessibilityHint: String {
        switch bulkDownloadHelper.state {
        case .downloaded:
            return Strings.bulkDownloadDeleteAllHint
        case .downloading:
            return Strings.bulkDownloadCancelAndDeleteHint
        default:
            return Strings.bulkDownloadAllHint
        }
    }
    
    var progressAccessibilityLabel: String? {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = NumberFormatter.Style.percent
        if let percentStr = percentFormatter.string(from: NSNumber(value: bulkDownloadHelper.progress)) {
            let numeric = Int(bulkDownloadHelper.progress * 100)
            return Strings.accessibilityDownloadProgressButton(percentComplete: numeric, formatted: percentStr)
        }
        return nil
    }
    
    // MARK: - Initializers -
    init(with course: OEXCourse) {
        bulkDownloadHelper = BulkDownloadHelper(with: course)
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
            observer.updateView()
        }
        let notificationObserver = NotificationObserver(notification: notification, observer: observer)
        observers.append(notificationObserver)
    }
    
    fileprivate func removeObserver(notificationObserver: NotificationObserver) {
        notificationObserver.observer.remove()
        NotificationCenter.default.removeObserver(self, name: notificationObserver.notification, object: nil)
    }
    
    fileprivate func handleProgressChangeObserver() {
        let progressChangedNotification = NSNotification.Name.OEXDownloadProgressChanged
        if bulkDownloadHelper.state == .downloading {
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
    
    func updateView() {
        guard toggleAction == nil else { return }
        bulkDownloadHelper.refreshState()
        toggleSwitch.isOn = toggleOn
        downloadProgressView.isHidden = bulkDownloadHelper.state != .downloading
        spinner.isHidden = bulkDownloadHelper.state != .downloading
        imageView.isHidden = bulkDownloadHelper.state == .downloading
        titleLabel.attributedText = titleLabelStyle.attributedString(withText: title)
        subTitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: subTitle)
        downloadProgressView.setProgress(bulkDownloadHelper.progress, animated: true)
        showDownloadsButton.isAccessibilityElement = bulkDownloadHelper.state == .downloading
        downloadProgressView.accessibilityLabel = progressAccessibilityLabel
        toggleSwitch.accessibilityHint = toggleAccessibilityHint
        handleProgressChangeObserver()
    }
    
    private func switchToggled(){
        toggleAction?.cancel()
        if toggleSwitch.isOn {
            toggleAction = DispatchWorkItem { self.startDownloading() }
            DispatchQueue.main.async(execute: toggleAction!)
        }
        else {
            toggleAction = DispatchWorkItem { self.stopAndDeleteDownloads() }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + toggleActionDelay, execute: toggleAction!)
            OEXAnalytics.shared().trackBulkDownloadToggle(on: false, courseID: bulkDownloadHelper.course.course_id ?? "", totalVideosCount: bulkDownloadHelper.courseVideos.count, remainingVideosCount: bulkDownloadHelper.newVideosCount)
        }
        
    }
    
    private func startDownloading() {
        OEXInterface.shared().downloadVideos(bulkDownloadHelper.courseVideos) {
            [weak self] cancelled in
            self?.toggleAction = nil
            if cancelled {
                self?.updateView()
            }
            else {
                if let owner = self {
                    OEXAnalytics.shared().trackBulkDownloadToggle(on: true, courseID: owner.bulkDownloadHelper.course.course_id ?? "", totalVideosCount: owner.bulkDownloadHelper.courseVideos.count, remainingVideosCount: owner.bulkDownloadHelper.newVideosCount)
                }
            }
        }
    }
    
    private func stopAndDeleteDownloads() {
        OEXInterface.shared().deleteDownloadedVideos(bulkDownloadHelper.courseVideos) { [weak self] _ in
            self?.toggleAction = nil
            self?.updateView()
        }
    }
    
    private func configureView() {
        backgroundColor = styles.neutralXXLight()
        addSubviews()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Icon.CourseVideos.imageWithFontSize(size: 20)
        
        showDownloadsButton.oex_addAction({ [weak self] _ in
            if let owner = self, owner.toggleSwitch.isOn && owner.bulkDownloadHelper.state == .downloading {
                    owner.delegate?.courseVideosHeaderViewTapped()
            }
            }, for: .touchUpInside)
    }
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(spinner)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(showDownloadsButton)
        addSubview(toggleSwitch)
        addSubview(downloadProgressView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        
        imageView.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.centerY.equalTo(self.snp_centerY)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        
        spinner.snp_makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        
        titleLabel.snp_makeConstraints { make in
            make.leading.equalTo(imageView.snp_trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(toggleSwitch.snp_leading).offset(-StandardHorizontalMargin)
            make.top.equalTo(self).offset(1.5 * StandardVerticalMargin)
        }
        
        subTitleLabel.snp_makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom).offset(StandardVerticalMargin / 2)
        }
        
        showDownloadsButton.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        toggleSwitch.snp_makeConstraints { make in
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.centerY.equalTo(self.snp_centerY)
        }
        
        downloadProgressView.snp_makeConstraints {make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(2)
            make.top.equalTo(subTitleLabel.snp_bottom).offset(1.5 * StandardVerticalMargin)
        }
    }
    
    // MARK: - Computed Properties -
    var image: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
        }
    }
    
//    var title: String? {
//        get {
//            return titleLabel.text
//        }
//        set {
//            titleLabel.attributedText = titleLabelStyle.attributedString(withText: newValue)
//        }
//    }
//
//    var subTitle: String? {
//        get {
//            return subTitleLabel.text
//        }
//        set {
//            subTitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: newValue)
//        }
//    }
}
