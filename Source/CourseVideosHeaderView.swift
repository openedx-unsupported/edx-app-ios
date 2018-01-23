//
//  CourseVideosHeaderView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 16/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol CourseVideosHeaderViewDelegate: class {
    func courseVideosHeaderViewDidTapped()
}

fileprivate struct NotificationObserver {
    var notification: NSNotification.Name
    var observer: Removable
}

class CourseVideosHeaderView: UIView {
    
    static var height: CGFloat = 72.0
    private let toggleActionDelay = 2.0 // In Seconds
    
    private let courseVideosHelper: CourseVideosHelper
    private var toggleAction: DispatchWorkItem?
    weak var delegate: CourseVideosHeaderViewDelegate?
    private var observers:[NotificationObserver] = []
    
    // MARK: - UI Properties -
    lazy private var imageView: UIImageView = UIImageView()
    private let downloadSpinner = SpinnerView(size: .Medium, color: .Primary)
    lazy private var titleLabel: UILabel = UILabel()
    lazy private var subTitleLabel: UILabel = UILabel()
    //        {
    //        let label = UILabel()
    //        label.numberOfLines = 2
    //        return label
    //    }()
    lazy private var showDownloadsButton: UIButton = UIButton()
    lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = self.styles.utilitySuccessBase()
        toggleSwitch.tintColor = self.styles.neutralLight()
        toggleSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
                owner.removeObservers(exceptDownloadStarted: true)
                owner.switchToggled()
            }
            }, for: .valueChanged)
        return toggleSwitch
    }()
    
    lazy private var downloadProgressView: UIProgressView = {
        let progressView = UIProgressView()
        progressView.tintColor = self.styles.utilitySuccessBase()
        progressView.trackTintColor = self.styles.neutralXLight()
        return progressView
    }()
    
    private var styles : OEXStyles {
        return OEXStyles.shared()
    }
    
    private var titleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: styles.primaryBaseColor())
    }
    
    private var subTitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : styles.neutralDark())
    }
    
    // MARK: - Initializers -
    init(with course: OEXCourse) {
        courseVideosHelper = CourseVideosHelper(with: course)
        super.init(frame: .zero)
        configureView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods -
    
    func addObservers(exceptDownloadStarted: Bool = false) {
        if !exceptDownloadStarted {
            observers.removeAll()
            let notification = NSNotification.Name.OEXDownloadStarted
            let observer = NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (_, observer, _) in
                observer.toggleAction = nil
                observer.addObservers(exceptDownloadStarted: true)
            }
            let notificationObserver = NotificationObserver(notification: notification, observer: observer)
            observers.append(notificationObserver)
        }
        else {
            // Remove All Observers except DownloadStarted Notification Observer
            observers = observers.filter { $0.notification ==  NSNotification.Name.OEXDownloadStarted }
        }
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded] {
            let observer = NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (_, observer, _) -> Void in
                observer.updateProgressDisplay()
            }
            let notificationObserver = NotificationObserver(notification: notification, observer: observer)
            observers.append(notificationObserver)
        }
    }
    
    func removeObservers(exceptDownloadStarted: Bool = false) {
        let removeableObservers = exceptDownloadStarted ? observers.filter { $0.notification !=  NSNotification.Name.OEXDownloadStarted } : observers
        for notificationObserver in removeableObservers {
            notificationObserver.observer.remove()
            NotificationCenter.default.removeObserver(self, name: notificationObserver.notification, object: nil)
        }
    }
    
    func updateProgressDisplay() {
        guard toggleAction == nil else { return }
        
        if courseVideosHelper.isDownloadedAllVideos {
            title = "All Videos Downloaded"
            subTitle = "\(courseVideosHelper.courseVideos.count) Videos, \(courseVideosHelper.totalSize.bytesToMB.twoDecimalPlaces)MB total"
            
            toggleSwitch.isOn = true
            downloadProgressView.isHidden = true
            downloadSpinner.isHidden = true
            imageView.isHidden = false
        }
        else if courseVideosHelper.isDownloadingAllVideos {
            title = "Downloading Videos..."
            subTitle = "\(courseVideosHelper.newOrPartiallyDownloadedVideos.count) Remaining, \(courseVideosHelper.remainingSize.bytesToMB.twoDecimalPlaces)MB"
            toggleSwitch.isOn = true
            downloadProgressView.isHidden = false
            downloadProgressView.progress = Float(courseVideosHelper.downloadedSize / courseVideosHelper.totalSize)
            downloadSpinner.isHidden = false
            imageView.isHidden = true
            
        }
        else {
            if courseVideosHelper.isDownloadedAnyVideo ||
                courseVideosHelper.isDownloadingAnyVideo {
                let remainingSize = courseVideosHelper.totalSize - courseVideosHelper.fullyDownloadedVideosSize
                subTitle = "\(courseVideosHelper.newOrPartiallyDownloadedVideos.count) Remaining, \(remainingSize.bytesToMB.twoDecimalPlaces)MB"
            }
            else {
                subTitle = "\(courseVideosHelper.courseVideos.count) videos, \(courseVideosHelper.totalSize.bytesToMB.twoDecimalPlaces)MB total"
            }
            title = "Download to Device"
            
            toggleSwitch.isOn = false
            downloadProgressView.isHidden = true
            downloadSpinner.isHidden = true
            imageView.isHidden = false
        }
    }
    
    private func switchToggled(){
        toggleAction?.cancel()
        toggleAction = nil
        toggleAction = toggleSwitch.isOn ? DispatchWorkItem { self.startDownloading() }
            : DispatchWorkItem { self.stopAndDeleteDownloads() }
        if toggleSwitch.isOn {
            DispatchQueue.main.async(execute: toggleAction!)
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + toggleActionDelay, execute: toggleAction!)
        }
    }
    
    private func startDownloading() {
        OEXInterface.shared().downloadVideos(courseVideosHelper.newVideos) {
            [weak self] cancelled in
            if cancelled {
                if let owner = self {
                    owner.toggleAction = nil
                    owner.updateProgressDisplay()
                    owner.addObservers(exceptDownloadStarted: true)
                }
            }
        }
    }
    
    private func stopAndDeleteDownloads() {
        OEXInterface.shared().deleteDownloadedVideos(courseVideosHelper.partialyOrFullyDownloadedVideos) { [weak self] _ in
            if let owner = self {
                owner.toggleAction = nil
                owner.updateProgressDisplay()
                owner.addObservers(exceptDownloadStarted: true)
            }
        }
    }
    
    private func configureView() {
        backgroundColor = styles.neutralXXLight()
        addSubviews()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Icon.CourseVideos.imageWithFontSize(size: 20)
        
        showDownloadsButton.oex_addAction({ [weak self] _ in
            if let owner = self, owner.toggleSwitch.isOn && !owner.courseVideosHelper.isDownloadedAllVideos  {
                owner.delegate?.courseVideosHeaderViewDidTapped()
            }
            }, for: .touchUpInside)
    }
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(downloadSpinner)
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
        
        downloadSpinner.snp_makeConstraints { make in
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
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = titleLabelStyle.attributedString(withText: newValue)
        }
    }
    
    var subTitle: String? {
        get {
            return subTitleLabel.text
        }
        set {
            subTitleLabel.attributedText = subTitleLabelStyle.attributedString(withText: newValue)
        }
    }
}

extension Double {
    var bytesToMB: Double {
        return self / 1024 / 1024
    }
    
    var twoDecimalPlaces: Double {
        return (100 * self).rounded() / 100.0
    }
}
