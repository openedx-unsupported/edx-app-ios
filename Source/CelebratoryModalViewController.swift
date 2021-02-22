//
//  CelebratoryModalViewController.swift
//  edX
//
//  Created by Salman on 22/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit
import MessageUI

private let UTM_ParameterString = "utm_campaign=edxmilestone&utm_medium=social&utm_source="

enum ActivityType:String {
    case linkedin = "com.linkedin.LinkedIn.ShareExtension"
}

private enum ShareButtonType {
    case linkedin
    case twitter
    case facebook
    case email
    case none
    
    var source: String {
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
    
    var parameter: String {
        return String(format: UTM_ParameterString, source)
    }
    
    static var utmParameters: CourseShareUtmParameters? {
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
    
    typealias Environment = NetworkManagerProvider & OEXInterfaceProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXAnalyticsProvider
    
    private let environment: Environment
    private var courseID: String
    private let type: ShareButtonType = .none
    
    private lazy var modalView: UIView = {
        let view = UIView()
        view.backgroundColor = environment.styles.neutralWhite()
        return view
    }()
    
    private lazy var congratulationImageView :UIImageView = {
        let imageView = UIImageView(image: UIImage.gifImageWithName("CelebrateClaps"))
        return imageView
        
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        let style = OEXMutableTextStyle(weight: .semiBold, size: .xxxLarge, color: environment.styles.neutralBlackT())
        style.alignment = .center
        title.attributedText = style.attributedString(withText: Strings.celebrationModalTitle)
        return title
    }()
    
    private lazy var titleMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        let style = OEXMutableTextStyle(weight: .normal, size: .large, color: environment.styles.neutralBlackT())
        style.alignment = .center
        message.attributedText = style.attributedString(withText: Strings.celebrationModalTitleMessage)
        return message
    }()
    
    private lazy var celebrationMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: environment.styles.neutralBlackT())
        style.alignment = .center
        message.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        message.adjustsFontSizeToFitWidth = true
        let string = Strings.celebrationModalInfoMessage
        let range = (string as NSString).range(of: "You earned it!")
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: message.font.pointSize), range: range)
        message.attributedText =  attributedString
        
        return message
    }()
    
    private lazy var keepGoingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = environment.styles.primaryBaseColor()
        let buttonStyle = OEXMutableTextStyle(weight: .normal, size: .xLarge, color: environment.styles.neutralWhiteT())
        button.setAttributedTitle(buttonStyle.attributedString(withText: Strings.celebrationKeepGoingButtonTitle), for: UIControl.State())
        button.oex_addAction({ [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var shareImageView: UIImageView = {
        let shareImage = UIImage(named: "shareCourse")?.withRenderingMode(.alwaysTemplate)
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
        
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        view.setNeedsUpdateConstraints()
        view.addSubview(modalView)
        
        setupViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackCourseCelebrationFirstSection(courseID: courseID)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func removeViews() {
        modalView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    private func setupViews() {
        if isLandscape {
            removeViews()
            setupLandscapeView()
        } else {
            removeViews()
            setupPortraitView()
        }
    }
    
    private func setupPortraitView() {
        let stackView = UIStackView()
        let insideContainer = UIView()
        let keepGoingButtonContainer = UIView()
        let buttonContainer = UIView()
        let textContainer = UIView()
        modalView.addSubview(stackView)
        
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = StandardVerticalMargin * 2
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(titleMessageLabel)
        stackView.addArrangedSubview(congratulationImageView)
        stackView.addArrangedSubview(insideContainer)
        stackView.addArrangedSubview(keepGoingButtonContainer)
        
        insideContainer.backgroundColor =  environment.styles.infoXXLight()
        insideContainer.addSubview(buttonContainer)
        insideContainer.addSubview(textContainer)
        insideContainer.addSubview(shareButtonView)
        
        shareButtonView.superview?.bringSubviewToFront(shareButtonView)
        
        textContainer.addSubview(celebrationMessageLabel)
        buttonContainer.addSubview(shareImageView)
        keepGoingButtonContainer.addSubview(keepGoingButton)
        
        shareImageView.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.width.equalTo(21)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.leading.equalTo(buttonContainer).offset(StandardHorizontalMargin*2)
            make.top.equalTo(buttonContainer).offset(isiPad() ? 10 : 0)
        }
        
        celebrationMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(textContainer).offset(isiPad() ? -StandardVerticalMargin : 0)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
            make.bottom.equalTo(textContainer)
        }
        
        buttonContainer.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.leading.equalTo(insideContainer)
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin*2)
        }

        textContainer.snp.remakeConstraints { make in
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin*2)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideContainer).inset(StandardHorizontalMargin*2)
            make.bottom.equalTo(insideContainer).inset(StandardVerticalMargin*2)
        }
        
        shareButtonView.snp.makeConstraints { make in
            make.edges.equalTo(insideContainer)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(30)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        
        insideContainer.snp.remakeConstraints { make in
            make.height.equalTo(100)
        }
        
        keepGoingButtonContainer.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.leading.equalTo(keepGoingButtonContainer).offset(StandardHorizontalMargin*4)
            make.trailing.equalTo(keepGoingButtonContainer).inset(StandardHorizontalMargin*4)
            make.height.equalTo(keepGoingButtonContainer)
        }
                
        modalView.snp.remakeConstraints { make in
            make.leading.equalTo(view).offset(isiPad() ? 100 : 20)
            make.trailing.equalTo(view).inset(isiPad() ? 100 : 20)
            let isiPhone7OrLess = UIScreen.main.bounds.height < 670.0
            let topAndBottomOffsetMargins = isiPhone7OrLess ? ((view.frame.size.height / 5) / 2) : ((view.frame.size.height / 3.2) / 2)
            make.top.equalTo(view).offset(topAndBottomOffsetMargins)
            make.bottom.equalTo(view).inset(topAndBottomOffsetMargins)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        
        stackView.snp.remakeConstraints { make in
            make.edges.equalTo(modalView).inset(20)
        }
    }
    
    private func setupLandscapeView() {
        let stackView = UIStackView()
        let rightStackView = UIStackView()
        let rightContainer = UIView()
        let insideContainer = UIView()
        let buttonContainer = UIView()
        let textContainer = UIView()
        let keepGoingButtonContainer = UIView()
        
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
            make.height.equalTo(30)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        
        insideContainer.snp.remakeConstraints { make in
            make.height.equalTo(100)
        }
        
        shareImageView.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.width.equalTo(21)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.leading.equalTo(buttonContainer).offset(StandardHorizontalMargin*2)
            make.top.equalTo(buttonContainer).offset(isiPad() ? 20 : 10)
            make.bottom.equalTo(buttonContainer)
        }

        celebrationMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(textContainer).offset(isiPad() ? -StandardVerticalMargin : 0)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
            make.bottom.equalTo(textContainer)
        }

        shareButtonView.snp.makeConstraints { make in
            make.edges.equalTo(insideContainer)
        }
        
        buttonContainer.snp.remakeConstraints { make in
            make.height.equalTo(isiPad() ? 40 : 30)
            make.leading.equalTo(insideContainer)
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin)
        }
            
        textContainer.snp.remakeConstraints { make in
            make.top.equalTo(insideContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideContainer).inset(StandardHorizontalMargin*2)
            make.bottom.equalTo(insideContainer).inset(StandardVerticalMargin)
        }
        
        keepGoingButtonContainer.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        
        keepGoingButton.snp.remakeConstraints { make in
            make.leading.equalTo(keepGoingButtonContainer).offset((view.frame.size.height / 4) / 2)
            make.trailing.equalTo(keepGoingButtonContainer).inset((view.frame.size.height / 4) / 2)
            make.height.equalTo(keepGoingButtonContainer)
        }
        
        modalView.snp.remakeConstraints { make in
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
            Strings.celebrationShareMessage(courseName: courseName, platformName: hashtagOrPlatform)
        }, url: courseURL, utmParams: utmParameters, analyticsCallback: { [weak self] analyticsType in
            self?.environment.analytics.trackCourseCelebrationSocialShareClicked(courseID: courseID, type: analyticsType)
        })
        controller.configurePresentationController(withSourceView: shareImageView)
        present(controller, animated: true, completion: nil)
    }
}
