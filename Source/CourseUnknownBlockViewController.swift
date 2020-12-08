//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & OEXAnalyticsProvider & OEXConfigProvider & OEXStylesProvider
    
    private let environment : Environment
    
    private let imageSize: CGFloat = 20
    
    let blockID: CourseBlockID?
    let courseID: String
    private var block: CourseBlock? {
        didSet {
            navigationItem.title = block?.displayName
        }
    }
    private var messageView: IconMessageView?
    private lazy var valuePropView = UIView(frame: .zero)
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
                } else {
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
            guard let videoURL = videoUrl, let url = URL(string: videoURL), UIApplication.shared.canOpenURL(url) else { return }
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
                showValuePropMessageView()
            } else {
                showGatedContentMessageView()
            }
        } else {
            showCourseContentUnknownView()
        }
    }
    
    private func showGatedContentMessageView() {
        configureIconMessage(with: IconMessageView(icon: Icon.Closed, message: Strings.courseContentGated))
    }
    
    private func showCourseContentUnknownView() {
        configureIconMessage(with: IconMessageView(icon: Icon.CourseUnknownContent, message: Strings.courseContentUnknown))
    }
    
    private func configureIconMessage(with view: IconMessageView) {
        messageView = view
        
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
    
    private func showValuePropMessageView() {
        container.backgroundColor = environment.styles.accentAColor()
        
        let titleContainer = UIView()
        let messageContainer = UIView()
        let buttonContainer = UIView()
        
        let bannerViewHeight = StandardHorizontalMargin * 12
        let leadingOffset = StandardHorizontalMargin * 4
        let buttonHeight = StandardVerticalMargin * 4
        let buttonMinimunWidth = StandardHorizontalMargin * 6
        
        let imageView = UIImageView()
        imageView.image = Icon.Closed.imageWithFontSize(size: imageSize).image(with: environment.styles.primaryDarkColor())
        imageView.accessibilityIdentifier = "ValueProp:image-view"
        
        let titleLabel = UILabel()
        titleLabel.accessibilityIdentifier = "ValueProp:label-title"
        titleLabel.numberOfLines = 0
        let titleStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.primaryDarkColor())
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.courseContentGatedLocked)
        
        let messageLabel = UILabel()
        messageLabel.accessibilityIdentifier = "ValueProp:label-message"
        messageLabel.numberOfLines = 0
        let messageStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.primaryDarkColor())
        messageLabel.attributedText = messageStyle.attributedString(withText: Strings.courseContentGatedUpgradeToAccessGraded)
        
        let buttonLearnMore = UIButton()
        buttonLearnMore.accessibilityIdentifier = "ValueProp:button-learn-more"
        buttonLearnMore.backgroundColor = environment.styles.neutralWhiteT()
        let buttonStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: environment.styles.primaryDarkColor())
        buttonLearnMore.setAttributedTitle(buttonStyle.attributedString(withText: Strings.courseContentGatedLearnMore), for: UIControl.State())
        
        valuePropView.accessibilityIdentifier = "ValueProp:view"
        
        titleContainer.addSubview(imageView)
        titleContainer.addSubview(titleLabel)
        messageContainer.addSubview(messageLabel)
        buttonContainer.addSubview(buttonLearnMore)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = StandardVerticalMargin / 2
        
        stackView.addArrangedSubview(titleContainer)
        stackView.addArrangedSubview(messageContainer)
        stackView.addArrangedSubview(buttonContainer)
        
        container.addSubview(stackView)
        valuePropView.addSubview(container)
        view.addSubview(valuePropView)
        
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
            make.height.equalTo(buttonHeight)
            make.bottom.equalTo(buttonContainer).inset(StandardVerticalMargin * 2)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.width.greaterThanOrEqualTo(buttonMinimunWidth)
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
                
        valuePropView.snp.makeConstraints { make in
            make.top.equalTo(StandardHorizontalMargin * 2)
            make.leading.equalTo(view).offset(StandardVerticalMargin)
            make.trailing.equalTo(view).inset(StandardVerticalMargin)
            make.height.greaterThanOrEqualTo(bannerViewHeight)
        }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(valuePropView)
            make.bottom.equalTo(valuePropView)
            make.leading.equalTo(valuePropView)
            make.trailing.equalTo(valuePropView)
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
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
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
        
        loader = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment).blockWithID(id: blockID).map { $0.webURL as URL? }.firstSuccess()
    }
    
    private func logOpenInBrowserEvent() {
        guard let block = block else { return }
        
        environment.analytics.trackOpenInBrowser(withURL: block.blockURL?.absoluteString ?? "", courseID: courseID, blockID: block.blockID, minifiedBlockID: block.minifiedBlockID ?? "", supported: block.multiDevice)
    }
}
