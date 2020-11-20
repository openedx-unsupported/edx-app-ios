//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & OEXAnalyticsProvider & OEXConfigProvider
    
    private let environment : Environment
    
    let blockID: CourseBlockID?
    let courseID: String
    private var block: CourseBlock?
    private var messageView: IconMessageView?
    private lazy var bannerErrorView = UIView(frame: .zero)
    private lazy var container = UIView()
    private lazy var stackView = TZStackView()
    
    private var loader: OEXStream<URL?>?
    
    init(blockID: CourseBlockID?, courseID: String, environment: Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: self.courseID, environment: environment)
        courseQuerier.blockWithID(id: blockID).extendLifetimeUntilFirstResult (
            success: { [weak self] block in
                self?.block = block
                if let video = block.type.asVideo, video.isYoutubeVideo {
                    self?.showYoutubeMessage(buttonTitle: Strings.Video.viewOnYoutube, message: Strings.Video.onlyOnYoutube, icon: Icon.CourseVideos, videoUrl: video.videoURL)
                }
                else {
                    self?.showError()
                }
            },
            failure: { [weak self] _ in
                self?.showError()
            }
        )
    }
    
    private func showYoutubeMessage(buttonTitle: String, message: String, icon: Icon, videoUrl: String?) {
        messageView = IconMessageView(icon: icon, message: message)
        messageView?.buttonInfo = MessageButtonInfo(title : buttonTitle) {
            guard let videoURL = videoUrl, let url =  URL(string: videoURL), UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.openURL(url)
        }
        
        if let messageView = messageView {
            view.addSubview(messageView)
        }
    }
    
    private func showError() {
        let flag = true
        
        if let block = block, block.isGated {
            if flag {
                showUpdatedError()
                return
            } else {
                messageView = IconMessageView(icon: Icon.Closed, message: Strings.courseContentGated)
            }
        }
        else {
            messageView = IconMessageView(icon: Icon.CourseUnknownContent, message: Strings.courseContentUnknown)
        }
        
        messageView?.buttonInfo = MessageButtonInfo(title : Strings.openInBrowser) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loader?.listen(weakSelf, success : { url in
                guard let url = url, UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.openURL(url)
                weakSelf.logOpenInBrowserEvent()
            }, failure : { _ in })
        }
        if let messageView = messageView {
            view.addSubview(messageView)
        }
    }
    
    private func showUpdatedError() {
        let bannerViewHeight = StandardHorizontalMargin * 12
        let leadingOffset = StandardHorizontalMargin * 4
                
        let imageView = UIImageView()
        let titleContainer = UIView()
        let messageContainer = UIView()
        let buttonContainer = UIView()
        
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        let titleTextStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralXDark())
        titleLabel.attributedText = titleTextStyle.attributedString(withText: Strings.courseContentGatedLocked)
        
        let messageLabel = UILabel()
        messageLabel.numberOfLines = 0
        let messageTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
        messageLabel.attributedText = messageTextStyle.attributedString(withText: Strings.courseContentGatedUpgradeToAccessGraded)
        
        let buttonLearnMore = UIButton()
        buttonLearnMore.layer.cornerRadius = 5
        buttonLearnMore.backgroundColor = OEXStyles.shared().primaryXLightColor()
        let buttonTextStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralWhite())
        buttonLearnMore.setAttributedTitle(buttonTextStyle.attributedString(withText: Strings.courseContentGatedLearnMore), for: UIControl.State())
        
        titleContainer.addSubview(imageView)
        titleContainer.addSubview(titleLabel)
        messageContainer.addSubview(messageLabel)
        buttonContainer.addSubview(buttonLearnMore)

        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = StandardVerticalMargin / 2
        
        stackView.addArrangedSubview(titleContainer)
        stackView.addArrangedSubview(messageContainer)
        stackView.addArrangedSubview(buttonContainer)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(stackView)
        bannerErrorView.addSubview(container)
        view.addSubview(bannerErrorView)
        
        imageView.image = Icon.Closed.imageWithFontSize(size: 20).image(with: OEXStyles.shared().primaryDarkColor())
        imageView.snp.makeConstraints { make in
            make.top.equalTo(StandardVerticalMargin * 2.2)
            make.leading.equalTo(container).offset(StandardHorizontalMargin + 4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(titleContainer)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(messageContainer)
        }

        buttonLearnMore.snp.makeConstraints { make in
            make.height.equalTo(StandardVerticalMargin * 4)
            make.bottom.equalTo(buttonContainer).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(buttonContainer)
            make.width.greaterThanOrEqualTo(StandardHorizontalMargin * 6)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(leadingOffset)
            make.trailing.equalTo(container)
            make.width.equalTo(container)
            make.height.equalTo(bannerViewHeight / 3)
        }
        
        messageContainer.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(leadingOffset)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(bannerViewHeight / 3)
        }
        
        buttonContainer.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(leadingOffset)
            make.trailing.equalTo(container)
            make.height.equalTo(bannerViewHeight / 3)
        }
                
        bannerErrorView.snp.makeConstraints { make in
            make.top.equalTo(StandardHorizontalMargin * 2)
            make.leading.equalTo(view).offset(StandardVerticalMargin)
            make.trailing.equalTo(view).inset(StandardVerticalMargin)
            make.height.greaterThanOrEqualTo(bannerViewHeight)
        }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(bannerErrorView)
            make.bottom.equalTo(bannerErrorView)
            make.leading.equalTo(bannerErrorView)
            make.trailing.equalTo(bannerErrorView)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(container)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
    }
    
    override func updateViewConstraints() {
        if isVerticallyCompact() {
            applyLandscapeConstraints()
        } else {
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        messageView?.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func applyLandscapeConstraints() {
        messageView?.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(safeBottom).offset(-barHeight)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loader = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: self.courseID, environment: environment).blockWithID(id: self.blockID).map { $0.webURL as URL? }.firstSuccess()
    }
    
    private func logOpenInBrowserEvent() {
        guard let block = block else { return }
        
        environment.analytics.trackOpenInBrowser(withURL: block.blockURL?.absoluteString ?? "", courseID: courseID, blockID: block.blockID, minifiedBlockID: block.minifiedBlockID ?? "", supported: block.multiDevice)
    }
}
