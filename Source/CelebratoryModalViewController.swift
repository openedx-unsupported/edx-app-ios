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
    
    private lazy var celebrationMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        message.adjustsFontSizeToFitWidth = true
        let earneditTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: environment.styles.neutralBlackT())
        let earneditAttributedString = earneditTextStyle.attributedString(withText: Strings.Celebration.earnedItText)
        let messageStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralBlackT())
        let messageAttributedString = messageStyle.attributedString(withText: Strings.Celebration.infoMessage)
        let compiledMessage = NSAttributedString.joinInNaturalLayout(attributedStrings: [earneditAttributedString, messageAttributedString])
        message.sizeToFit()
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
    
    private lazy var shareButtonView: UIButton = {
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
    
    private lazy var courseURL: String? = {
        return environment.interface?.enrollmentForCourse(withID: courseID)?.course.course_about
    }()
    
    private lazy var celebrationImageSize: CGSize = {
        let margin: CGFloat = isiPad() ? 240 : 80
        let width = view.frame.size.width - margin
        let imageAspectRatio: CGFloat = 1.37
        return CGSize(width: width, height: width / imageAspectRatio)
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
        view.setNeedsUpdateConstraints()
        view.addSubview(modalView)
        
        setupViews()
        setIdentifiers()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackCourseCelebrationFirstSection(courseID: courseID)
        markCelebratoryModalAsViewed()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func removeViews() {
        modalView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func setIdentifiers() {
        modalView.accessibilityIdentifier = "CelebratoryModalView:modal-container-view"
        titleLabel.accessibilityIdentifier = "CelebratoryModalView:label-title"
        titleMessageLabel.accessibilityIdentifier = "CelebratoryModalView:label-title-message"
        celebrationMessageLabel.accessibilityIdentifier = "CelebratoryModalView:label-celebration-message"
        congratulationImageView.accessibilityIdentifier = "CelebratoryModalView:congratulation-image-view"
        shareButtonView.accessibilityIdentifier = "CelebratoryModalView:share-button-view"
        shareImageView.accessibilityIdentifier = "CelebratoryModalView:share-image-view"
    }
    
    private func setupViews() {
        if isVerticallyCompact() {
            setupLandscapeView()
        } else {
            setupPortraitView()
        }
    }
    
    private func setupPortraitView() {
        removeViews()
        let imageContainer = UIView()
        let insideContainer = UIView()
        let keepGoingButtonContainer = UIView()
        let buttonContainer = UIView()
        let textContainer = UIView()
        
        modalView.addSubview(titleLabel)
        modalView.addSubview(titleMessageLabel)
        imageContainer.addSubview(congratulationImageView)
        modalView.addSubview(imageContainer)
        modalView.addSubview(insideContainer)
        modalView.addSubview(keepGoingButtonContainer)
        
        imageContainer.accessibilityIdentifier = "CelebratoryModalView:image-cotainer-view"
        insideContainer.accessibilityIdentifier = "CelebratoryModalView:share-inside-container-view"
        keepGoingButtonContainer.accessibilityIdentifier = "CelebratoryModalView:keep-going-button-container-view"
        buttonContainer.accessibilityIdentifier = "CelebratoryModalView:share-button-container-view"
        textContainer.accessibilityIdentifier = "CelebratoryModalView:share-text-container-view"
        
        insideContainer.backgroundColor = environment.styles.infoXXLight()
        insideContainer.addSubview(buttonContainer)
        insideContainer.addSubview(textContainer)
        insideContainer.addSubview(shareButtonView)
        
        shareButtonView.superview?.bringSubviewToFront(shareButtonView)
        
        textContainer.addSubview(celebrationMessageLabel)
        buttonContainer.addSubview(shareImageView)
        keepGoingButtonContainer.addSubview(keepGoingButton)

        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(modalView).offset(StandardVerticalMargin*3)
            make.centerX.equalTo(modalView)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
            make.height.equalTo(titleLabelHeight)
        }

        titleMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.centerX.equalTo(modalView)
            make.width.equalTo(imageContainer.snp.width).inset(10)
            make.height.equalTo(titleLabelMessageHeight)
        }
        
        congratulationImageView.snp.remakeConstraints { make in
            make.edges.equalTo(imageContainer)
        }

        imageContainer.snp.remakeConstraints { make in
            make.top.equalTo(titleMessageLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.centerX.equalTo(modalView)
            make.width.equalTo(celebrationImageSize.width)
            make.height.equalTo(celebrationImageSize.height)
        }

        insideContainer.snp.remakeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom).offset(StandardVerticalMargin * 2)
            make.centerX.equalTo(modalView)
            make.width.equalTo(imageContainer.snp.width)
            make.height.equalTo(shareButtonContainerHeight)
        }

        buttonContainer.snp.remakeConstraints { make in
            make.leading.equalTo(insideContainer)
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(insideContainer)
        }

        textContainer.snp.remakeConstraints { make in
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(insideContainer).inset(StandardVerticalMargin * 2)
        }

        shareImageView.snp.remakeConstraints { make in
            make.top.equalTo(celebrationMessageLabel.snp.top)
            make.leading.equalTo(buttonContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.width.equalTo(shareImageSize.width)
            make.height.equalTo(shareImageSize.height)
        }

        celebrationMessageLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(textContainer)
            make.centerY.equalTo(textContainer)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
        }
        
        shareButtonView.snp.makeConstraints { make in
            make.edges.equalTo(insideContainer)
        }
        
        keepGoingButtonContainer.snp.remakeConstraints { make in
            make.top.equalTo(insideContainer.snp.bottom).offset(StandardVerticalMargin * 3)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
            make.height.equalTo(keepGoingButtonSize.height)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.centerX.equalTo(keepGoingButtonContainer)
            make.height.equalTo(keepGoingButtonContainer)
            make.width.equalTo(keepGoingButtonSize.width)
        }
                
        modalView.snp.remakeConstraints { make in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
            let height = titleLabelHeight + titleLabelMessageHeight + celebrationImageSize.height + shareButtonContainerHeight + keepGoingButtonSize.height + (StandardVerticalMargin * 15)
            make.height.equalTo(height)
            make.width.equalTo(celebrationImageSize.width + StandardVerticalMargin * 5)
        }
    }
    
    private func setupLandscapeView() {
        removeViews()
        let stackView = UIStackView()
        let rightStackView = UIStackView()
        let rightContainer = UIView()
        let insideContainer = UIView()
        let buttonContainer = UIView()
        let textContainer = UIView()
        let keepGoingButtonContainer = UIView()
        
        stackView.accessibilityIdentifier = "CelebratoryModalView:stack-view"
        rightStackView.accessibilityIdentifier = "CelebratoryModalView:stack-right-view"
        rightContainer.accessibilityIdentifier = "CelebratoryModalView:stack-cotainer-right-view"
        insideContainer.accessibilityIdentifier = "CelebratoryModalView:share-inside-container-view"
        keepGoingButtonContainer.accessibilityIdentifier = "CelebratoryModalView:keep-going-button-container-view"
        buttonContainer.accessibilityIdentifier = "CelebratoryModalView:share-button-container-view"
        textContainer.accessibilityIdentifier = "CelebratoryModalView:share-text-container-view"
        
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = StandardVerticalMargin * 2
        insideContainer.backgroundColor = environment.styles.infoXXLight()
        
        modalView.addSubview(stackView)
        textContainer.addSubview(celebrationMessageLabel)
        buttonContainer.addSubview(shareImageView)
        insideContainer.addSubview(shareButtonView)
        insideContainer.addSubview(buttonContainer)
        insideContainer.addSubview(textContainer)
        
        shareButtonView.superview?.bringSubviewToFront(shareButtonView)
                
        rightStackView.alignment = .fill
        rightStackView.axis = .vertical
        rightStackView.distribution = .equalSpacing
        rightStackView.spacing = StandardVerticalMargin
        
        rightStackView.addArrangedSubview(titleLabel)
        rightStackView.addArrangedSubview(titleMessageLabel)
        rightStackView.addArrangedSubview(insideContainer)
        rightStackView.addArrangedSubview(keepGoingButtonContainer)
        
        stackView.addArrangedSubview(congratulationImageView)
        stackView.addArrangedSubview(rightContainer)
        
        rightContainer.addSubview(rightStackView)
        keepGoingButtonContainer.addSubview(keepGoingButton)
        
        rightStackView.snp.makeConstraints { make in
            make.edges.equalTo(rightContainer)
        }
        
        rightContainer.snp.remakeConstraints { make in
            make.height.equalTo(stackView)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(titleLabelHeight)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.height.equalTo(titleLabelMessageHeight)
        }
        
        insideContainer.snp.remakeConstraints { make in
            make.height.equalTo(shareButtonContainerHeight)
        }
        
        shareImageView.snp.remakeConstraints { make in
            make.top.equalTo(celebrationMessageLabel.snp.top)
            make.leading.equalTo(buttonContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.width.equalTo(shareImageSize.width)
            make.height.equalTo(shareImageSize.height)
        }

        celebrationMessageLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(textContainer)
            make.centerY.equalTo(textContainer)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
            make.height.lessThanOrEqualTo(textContainer)
        }

        shareButtonView.snp.makeConstraints { make in
            make.edges.equalTo(insideContainer)
        }
        
        buttonContainer.snp.remakeConstraints { make in
            make.leading.equalTo(insideContainer)
            make.top.equalTo(insideContainer)
            make.bottom.equalTo(insideContainer)
        }
            
        textContainer.snp.remakeConstraints { make in
            make.top.equalTo(insideContainer)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(insideContainer).inset(StandardVerticalMargin)
        }
        
        keepGoingButtonContainer.snp.remakeConstraints { make in
            make.height.equalTo(keepGoingButtonSize.height)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.centerX.equalTo(keepGoingButtonContainer)
            make.height.equalTo(keepGoingButtonContainer)
            make.width.equalTo(keepGoingButtonSize.width)
        }
        
        modalView.snp.remakeConstraints { make in
            // For iPad the modal is streching to the end of the screen so we restricted the modal top, bottom, leading
            // and trailing margin for iPad
            
            make.leading.equalTo(view).offset(isiPad() ? 100 : 40)
            make.trailing.equalTo(view).inset(isiPad() ? 100 : 40)
            
            let top = isiPad() ? ((view.frame.size.height / 2.5 ) / 2) : ((view.frame.size.height / 4) / 2)
            let bottom = isiPad() ? ((view.frame.size.width / 2.5 ) / 2) : ((view.frame.size.height / 4) / 2)
            make.top.equalTo(view).offset(top)
            make.bottom.equalTo(view).inset(bottom)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        
        stackView.snp.remakeConstraints { make in
            make.edges.equalTo(modalView).inset(20)
        }
    }
    
    @objc func orientationDidChange() {
        setupViews()
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
