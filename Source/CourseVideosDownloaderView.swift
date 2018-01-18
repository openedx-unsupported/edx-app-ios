//
//  CourseVideosDownloaderView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 16/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

protocol CourseVideosDownloaderViewDelegate {
    func courseVideosDownloaderViewDidTapped()
}
class CourseVideosDownloaderView: UIView {
    
    static var height: CGFloat = 72.0
    private let toggleActionDelay = 2.0 // In Seconds
    
    let courseVideosDownloader: CourseVideosDownloader
    var task: DispatchWorkItem?
    var delegate: CourseVideosDownloaderViewDelegate?
    
    // MARK: - UI Properties -
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    private let downloadSpinner = SpinnerView(size: .Medium, color: .Primary)
    lazy private var titleLabel: UILabel = UILabel()
    lazy private var subTitleLabel: UILabel = UILabel()
    
    lazy private var toggleSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.onTintColor = self.styles.utilitySuccessBase()
        toggleSwitch.tintColor = self.styles.neutralLight()
        toggleSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
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
    
    private var isToggledAutomatically = false
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
    init(with course: OEXCourse, delegate: CourseVideosDownloaderViewDelegate) {
        courseVideosDownloader = CourseVideosDownloader(with: course)
        self.delegate = delegate
        super.init(frame: .zero)
        configureView()
        
        for notification in [NSNotification.Name.OEXDownloadProgressChanged, NSNotification.Name.OEXDownloadEnded, NSNotification.Name.OEXDownloadedVideoDeleted] {
            NotificationCenter.default.oex_addObserver(observer: self, name: notification.rawValue) { (_, observer, _) -> Void in
                observer.updateProgressDisplay()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods -
    func updateProgressDisplay() {
        isToggledAutomatically = true
        if courseVideosDownloader.isDownloadedAllVideos {
            title = "All Videos Downloaded"
            subTitle = "\(courseVideosDownloader.courseVideos.count) Videos, \(courseVideosDownloader.totalSize.bytesToMB.twoDecimalPlaces)MB total"
            
            toggleSwitch.isOn = true
            downloadProgressView.isHidden = true
            downloadSpinner.isHidden = true
            imageView.isHidden = false
        }
        else if courseVideosDownloader.isDownloadingAllVideos {
            title = "Downloading Videos..."
            subTitle = "\(courseVideosDownloader.newOrPartiallyDownloadedVideos.count) Remaining, \(courseVideosDownloader.remainingSize.bytesToMB.twoDecimalPlaces)MB total"
            toggleSwitch.isOn = true
            downloadProgressView.isHidden = false
            downloadProgressView.progress = Float(courseVideosDownloader.downloadedSize / courseVideosDownloader.totalSize)
            downloadSpinner.isHidden = false
            imageView.isHidden = true
            
        }
        else {
            if courseVideosDownloader.isDownloadedAnyVideo ||
                courseVideosDownloader.isDownloadingAnyVideo {
                let remainingSize = courseVideosDownloader.totalSize - courseVideosDownloader.fullyDownloadedVideosSize
                subTitle = "\(courseVideosDownloader.newOrPartiallyDownloadedVideos.count) Remaining, \(remainingSize.bytesToMB.twoDecimalPlaces)MB total"
            }
            else {
                subTitle = "\(courseVideosDownloader.courseVideos.count) videos, \(courseVideosDownloader.totalSize.bytesToMB.twoDecimalPlaces)MB total"
            }
            title = "Download to Device"
            
            toggleSwitch.isOn = false
            downloadProgressView.isHidden = true
            downloadSpinner.isHidden = true
            imageView.isHidden = false
            
        }
        isToggledAutomatically = false
    }
    
    private func switchToggled(){
        if !isToggledAutomatically {
            task?.cancel()
            task = nil
            task = toggleSwitch.isOn ? DispatchWorkItem { self.startDownloading() }
                : DispatchWorkItem { self.stopAndDeleteDownloads() }
            if toggleSwitch.isOn {
                DispatchQueue.main.async(execute: task!)
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + toggleActionDelay, execute: task!)
            }
        }
        isToggledAutomatically = false
    }
    
    private func startDownloading() {
        OEXInterface.shared().downloadVideos(courseVideosDownloader.newVideos)
    }
    
    private func stopAndDeleteDownloads() {
        OEXInterface.shared().deleteDownloadedVideos(courseVideosDownloader.partialyOrFullyDownloadedVideos) { _ in }
    }
    
    private func configureView() {
        backgroundColor = styles.neutralXXLight()
        addSubviews()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Icon.CourseVideos.imageWithFontSize(size: 20)
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction { [weak self] _ in
            if let owner = self, owner.toggleSwitch.isOn && !owner.courseVideosDownloader.isDownloadedAllVideos  {
                owner.delegate?.courseVideosDownloaderViewDidTapped()
            }
        }
        addGestureRecognizer(tapGesture)
    }
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(downloadSpinner)
        addSubview(titleLabel)
        addSubview(subTitleLabel)
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
            make.trailing.equalTo(toggleSwitch.snp_leading).inset(StandardHorizontalMargin)
            make.top.equalTo(self).offset(1.5 * StandardVerticalMargin)
        }
        
        subTitleLabel.snp_makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom).offset(StandardVerticalMargin / 2)
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
