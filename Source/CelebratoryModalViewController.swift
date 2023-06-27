//
//  CelebratoryModalViewController.swift
//  edX
//
//  Created by Salman on 22/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

private let UTM_ParameterString = "utm_campaign=edxmilestone&utm_medium=social&utm_source=%@"

enum ActivityType:String {
    case linkedin = "com.linkedin.LinkedIn.ShareExtension"
}

protocol CelebratoryModalViewControllerDelegate: AnyObject {
    func modalDidDismiss()
}

private enum ShareButtonType {
    case linkedin
    case twitter
    case facebook
    case email
    case none
    
    private var source: String {
        switch self {
        case .linkedin:
            return "linkedin"
        case .twitter:
            return "twitter"
        case .facebook:
            return "facebook"
        case .email:
            return "email"
        default:
            return "other"
        }
    }
    
    private var parameter: String {
        return String(format: UTM_ParameterString, source)
    }
    
    fileprivate static var utmParameters: CourseShareUtmParameters? {
        let parameters: [String: String] = [
            ShareButtonType.facebook.source: ShareButtonType.facebook.parameter,
            ShareButtonType.twitter.source: ShareButtonType.twitter.parameter,
            ShareButtonType.linkedin.source: ShareButtonType.linkedin.parameter,
            ShareButtonType.email.source: ShareButtonType.email.parameter,
        ]
        return CourseShareUtmParameters(utmParams: parameters)
    }
}

class CelebratoryModalViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = NetworkManagerProvider & OEXInterfaceProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXAnalyticsProvider & DataManagerProvider
    
    private let environment: Environment
    private var courseID: String
    private let type: ShareButtonType = .none
    private let keepGoingButtonSize = CGSize(width: 140, height: 40)
    private let shareImageSize = CGSize(width: 22, height: 22)
    private let titleLabelHeight:CGFloat = 30.0
    private let titleLabelMessageHeight:CGFloat = 40.0
    private let shareButtonContainerHeight:CGFloat = 100.0
    weak var delegate : CelebratoryModalViewControllerDelegate?
    
    private lazy var modalView: UIView = {
        let view = UIView()
        view.backgroundColor = environment.styles.neutralWhite()
        return view
    }()
    
    private lazy var congratulationImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.gifImageWithName("CelebrateClaps"))
        imageView.contentMode = .scaleToFill
        return imageView
        
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        let style = OEXMutableTextStyle(weight: .bold, size: .xxxxLarge, color: environment.styles.neutralBlackT())
        style.alignment = .center
        title.attributedText = style.attributedString(withText: Strings.Celebration.title)
        return title
    }()
    
    private lazy var titleMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        let style = OEXMutableTextStyle(weight: .normal, size: .large, color: environment.styles.neutralBlackT())
        style.alignment = .center
        message.attributedText = style.attributedString(withText: Strings.Celebration.titleMessage)
        return message
    }()
    
    private lazy var shareMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        message.adjustsFontSizeToFitWidth = true
        let earneditTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: environment.styles.neutralBlackT())
        let earneditAttributedString = earneditTextStyle.attributedString(withText: Strings.Celebration.earnedItText)
        let messageStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralBlackT())
        let messageAttributedString = messageStyle.attributedString(withText: Strings.Celebration.infoMessage)
        let compiledMessage = NSAttributedString.joinInNaturalLayout(attributedStrings: [earneditAttributedString, messageAttributedString])
        message.attributedText = compiledMessage
        return message
    }()
    
    private lazy var keepGoingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = environment.styles.primaryBaseColor()
        let buttonStyle = OEXMutableTextStyle(weight: .normal, size: .xLarge, color: environment.styles.neutralWhiteT())
        button.setAttributedTitle(buttonStyle.attributedString(withText: Strings.Celebration.keepGoingButtonTitle), for: UIControl.State())
        button.oex_addAction({ [weak self] _ in
            self?.dismiss(animated: false, completion: { [weak self] in
                self?.delegate?.modalDidDismiss()
            })
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var shareImageView: UIImageView = {
        let shareImage = Icon.ShareCourse.imageWithFontSize(size: 24)
        let imageView = UIImageView(image: shareImage)
        return imageView
    }()
    
    private lazy var shareButton: UIButton = {
        let button = UIButton()
        button.accessibilityLabel = Strings.Accessibility.shareACourse
        button.oex_removeAllActions()
        button.oex_addAction({ [weak self] _ in
            if let courseID = self?.courseID,
               let courseURL = self?.courseURL,
               let shareUtmParameters = ShareButtonType.utmParameters {
                self?.shareCourse(courseID: courseID, courseURL: courseURL, utmParameters: shareUtmParameters)
            }
        }, for: .touchUpInside)
        
        return button
    }()
    
    private let shareContainer = UIView()
    
    private lazy var courseURL: String? = {
        return environment.interface?.enrollmentForCourse(withID: courseID)?.course.course_about
    }()
    
    private lazy var celebrationImageSize: CGSize = {
        let margin: CGFloat = isiPad() ? 240 : 80
        let width = UIScreen.main.bounds.width - margin
        let imageAspectRatio: CGFloat = 1.37
        return CGSize(width: width, height: width / imageAspectRatio)
    }()
    
    private lazy var celebrationImageSizeLandscape: CGSize = {
        let margin: CGFloat = isiPad() ? 340 : 165
        let height = UIScreen.main.bounds.height - margin
        let imageAspectRatio: CGFloat = 1.37
        return CGSize(width: height * imageAspectRatio, height: height)
    }()
    
    init(courseID: String, environment: Environment) {
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.neutralXXDark().withAlphaComponent(0.5)
        
        addSubviews()
        setIdentifiers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackCourseCelebrationFirstSection(courseID: courseID)
        markCelebratoryModalAsViewed()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }
    
    
    override func updateViewConstraints() {
        if isVerticallyCompact() {
            setupLandscapeView()
        }
        else {
            setupPortraitView()
        }
        
        super.updateViewConstraints()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setIdentifiers() {
        modalView.accessibilityIdentifier = "CelebratoryModalView:modal-view"
        titleLabel.accessibilityIdentifier = "CelebratoryModalView:label-title"
        titleMessageLabel.accessibilityIdentifier = "CelebratoryModalView:title-message-label"
        shareMessageLabel.accessibilityIdentifier = "CelebratoryModalView:share-message-label"
        congratulationImageView.accessibilityIdentifier = "CelebratoryModalView:congratulation-image-view"
        shareButton.accessibilityIdentifier = "CelebratoryModalView:share-button"
        shareImageView.accessibilityIdentifier = "CelebratoryModalView:share-image-view"
        shareContainer.accessibilityIdentifier = "CelebratoryModalView:share-container-view"
    }
    
    private func addSubviews() {
        view.addSubview(modalView)
        
        modalView.addSubview(titleLabel)
        modalView.addSubview(titleMessageLabel)
        modalView.addSubview(congratulationImageView)
        modalView.addSubview(shareContainer)
        modalView.addSubview(keepGoingButton)
        
        shareContainer.backgroundColor = environment.styles.infoXXLight()
        shareContainer.addSubview(shareImageView)
        shareContainer.addSubview(shareMessageLabel)
        shareContainer.addSubview(shareButton)
        
        shareButton.superview?.bringSubviewToFront(shareButton)
    }
    
    private func setupPortraitView() {
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(modalView).offset(StandardVerticalMargin*3)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(congratulationImageView)
            make.trailing.equalTo(congratulationImageView)
        }
        
        congratulationImageView.snp.remakeConstraints { make in
            make.top.equalTo(titleMessageLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.centerX.equalTo(modalView)
            make.width.equalTo(celebrationImageSize.width)
            make.height.equalTo(celebrationImageSize.height)
        }
        
        shareContainer.snp.remakeConstraints { make in
            make.top.equalTo(congratulationImageView.snp.bottom).offset(StandardVerticalMargin * 2)
            make.centerX.equalTo(congratulationImageView)
            make.leading.equalTo(congratulationImageView)
            make.trailing.equalTo(congratulationImageView)
        }
        
        shareButton.snp.remakeConstraints { make in
            make.edges.equalTo(shareContainer)
        }
        
        shareImageView.snp.remakeConstraints { make in
            make.top.equalTo(shareContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(shareContainer).offset(StandardHorizontalMargin)
            make.width.equalTo(shareImageSize.width)
            make.height.equalTo(shareImageSize.height)
        }
        
        shareMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(shareImageView)
            make.leading.equalTo(shareImageView.snp.trailing).offset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(shareContainer).inset(StandardHorizontalMargin)
            make.bottom.equalTo(shareContainer).inset(StandardVerticalMargin * 2)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.top.equalTo(shareContainer.snp.bottom).offset(StandardVerticalMargin * 3)
            make.bottom.equalTo(modalView).inset(StandardVerticalMargin * 3)
            make.centerX.equalTo(modalView)
            make.height.equalTo(keepGoingButtonSize.height)
            make.width.equalTo(keepGoingButtonSize.width)
        }
        
        modalView.snp.remakeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
            make.leading.equalTo(safeLeading).offset(StandardHorizontalMargin)
            make.trailing.equalTo(safeTrailing).inset(StandardHorizontalMargin)
        }
    }
    
    private func setupLandscapeView() {
        congratulationImageView.snp.remakeConstraints { make in
            make.top.equalTo(modalView).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.width.equalTo(celebrationImageSizeLandscape.width)
            make.height.equalTo(celebrationImageSizeLandscape.height)
            make.bottom.equalTo(modalView).inset(StandardVerticalMargin * 2)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(congratulationImageView).offset(StandardVerticalMargin)
            make.leading.equalTo(congratulationImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }

        shareContainer.snp.remakeConstraints { make in
            make.top.greaterThanOrEqualTo(titleMessageLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        shareButton.snp.remakeConstraints { make in
            make.edges.equalTo(shareContainer)
        }
        
        shareImageView.snp.remakeConstraints { make in
            make.top.equalTo(shareContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(shareContainer).offset(StandardHorizontalMargin)
            make.width.equalTo(shareImageSize.width)
            make.height.equalTo(shareImageSize.height)
        }
        
        shareMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(shareImageView)
            make.leading.equalTo(shareImageView.snp.trailing).offset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(shareContainer).inset(StandardHorizontalMargin)
            make.bottom.equalTo(shareContainer).inset(StandardVerticalMargin * 2)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.top.equalTo(shareContainer.snp.bottom).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(modalView).inset(StandardVerticalMargin * 2)
            make.centerX.equalTo(shareMessageLabel)
            make.height.equalTo(keepGoingButtonSize.height)
            make.width.equalTo(keepGoingButtonSize.width)
        }
        
        
        modalView.snp.remakeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
            make.leading.equalTo(safeLeading).offset(StandardHorizontalMargin)
            make.trailing.equalTo(safeTrailing).inset(StandardHorizontalMargin)
        }
    }
    
    private func shareCourse(courseID: String, courseURL: String, utmParameters: CourseShareUtmParameters) {
        guard let courseURL = NSURL(string: courseURL),
            let enrollment = environment.interface?.enrollmentForCourse(withID: courseID),
            let courseName = enrollment.course.name else { return }
        
        let controller = shareHashtaggedTextAndALinkForCelebration(textBuilder: { hashtagOrPlatform in
            Strings.Celebration.shareMessage(courseName: courseName, platformName: hashtagOrPlatform, hashtagPlatformName: self.environment.config.platformName())
        }, url: courseURL, utmParams: utmParameters, analyticsCallback: { [weak self] analyticsType in
            self?.environment.analytics.trackCourseCelebrationSocialShareClicked(courseID: courseID, type: analyticsType)
        })
        controller.configurePresentationController(withSourceView: shareImageView)
        present(controller, animated: true, completion: nil)
    }
    
    private func markCelebratoryModalAsViewed() {
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        courseQuerier.updateCelebrationModalStatus(firstSection: false)
    }
}
