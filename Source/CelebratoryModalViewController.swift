//
//  CelebratoryModalViewController.swift
//  edX
//
//  Created by Salman on 22/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit
import MessageUI

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
        switch self {
        case .linkedin:
            return "utm_campaign=edxmilestone&utm_medium=social&utm_source=\(source)"
            
        case .twitter:
            return "utm_campaign=edxmilestone&utm_medium=social&utm_source=\(source)"
            
        case .facebook:
            return "utm_campaign=edxmilestone&utm_medium=social&utm_source=\(source)"
            
        case .email:
            return "utm_campaign=edxmilestone&utm_medium=social&utm_source=\(source)"
            
        default:
            return "utm_campaign=edxmilestone&utm_medium=social&utm_source=other"
        }
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
    
    typealias Environment = NetworkManagerProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & OEXAnalyticsProvider
    
    private let environment: Environment
    private var courseID: String
    private let type: ShareButtonType = .none
    
    private let modalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 8.0
        return view
    }()
    
    private lazy var congratulationImageView: UIImageView = {
        let gifImage = UIImage.gifImageWithName("CelebrateClaps")
        return UIImageView(image: gifImage)
    }()
    
    private lazy var titleLabel: UILabel = {
        let title = UILabel()
        let style = OEXMutableTextStyle(weight: .semiBold, size: .xxxLarge, color : OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        title.attributedText = style.attributedString(withText: "Congratulations!")
        return title
    }()
    
    private lazy var titleMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        //message.adjustsFontSizeToFitWidth = true
        let style = OEXMutableTextStyle(weight: .normal, size: .large, color : OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        message.attributedText = style.attributedString(withText: "You just completed the first section of your course!")
        return message
    }()
    
    private lazy var celebrationMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        //message.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        //message.adjustsFontSizeToFitWidth = true
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color : OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        let string = "You earned it! Take a moment to celebrate and share your progress"
        let range = (string as NSString).range(of: "You earned it!")
        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.boldSystemFont(ofSize: message.font.pointSize), range: range)
        
        message.attributedText =  attributedString// style.attributedString(withText: "You earned it! Take a moment to celebrate and share your progress")
        
        return message
    }()
    
    private lazy var keepGoingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = OEXStyles.shared().primaryBaseColor()
        button.layer.cornerRadius = 5.0
        let buttonStyle = OEXMutableTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared().neutralWhiteT())
        button.setAttributedTitle(buttonStyle.attributedString(withText: "Keep going"), for: UIControl.State())
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
    
    private lazy var courseURL:String = {
        let enrollment = OEXInterface.shared().enrollmentForCourse(withID: courseID)
        let courseURL = enrollment?.course.course_about ?? ""
        return courseURL
    }()
    
    private lazy var shareTextMessage: String = {
        let enrollment = OEXInterface.shared().enrollmentForCourse(withID: courseID)
        let courseName = enrollment?.course.name ?? ""
        let message = String(format: "I'm on my way to completing %@ online with @edxonline. What are you spending your time learning?", courseName)
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        return encodedMessage
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
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
            setupLandscapeConstraints()
        } else {
            removeViews()
            setupPortraitConstraints()
        }
    }
    
    private func setupPortraitConstraints() {
        let stackView = UIStackView()
        let insideContainer = UIView()
        let insideStackView = UIStackView()
        
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
        stackView.addArrangedSubview(keepGoingButton)
        
        insideStackView.alignment = .fill
        insideStackView.axis = .horizontal
        insideStackView.distribution = .equalSpacing
        insideStackView.spacing = StandardHorizontalMargin / 2
        
        insideStackView.addArrangedSubview(buttonContainer)
        insideStackView.addArrangedSubview(textContainer)
        
        insideContainer.addSubview(insideStackView)
        insideContainer.backgroundColor = OEXStyles.shared().infoXXLight()
        
        insideContainer.addSubview(shareButtonView)
        shareButtonView.superview?.bringSubviewToFront(shareButtonView)
        
        textContainer.addSubview(celebrationMessageLabel)
        buttonContainer.addSubview(shareImageView)
        
        shareImageView.snp.remakeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(26)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.top.equalTo(buttonContainer).offset(StandardVerticalMargin)
        }
        
        celebrationMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(textContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
        }
        
        buttonContainer.snp.remakeConstraints { make in
            make.width.equalTo(80)
        }
        
        textContainer.snp.remakeConstraints { make in
            make.height.equalTo(insideStackView)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideStackView).inset(StandardHorizontalMargin)
        }
        
        insideStackView.snp.remakeConstraints { make in
            make.edges.equalTo(insideContainer)
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
        
        keepGoingButton.snp.remakeConstraints { (make) in
            make.height.equalTo(44)
        }
        
        modalView.backgroundColor = .white
        
        modalView.snp.remakeConstraints { make in
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).inset(20)
            make.top.equalTo(view).offset((view.frame.size.height / 4) / 2)
            make.bottom.equalTo(view).inset((view.frame.size.height / 4) / 2)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        
        stackView.snp.remakeConstraints { make in
            make.edges.equalTo(modalView).inset(20)
        }
    }
    
    private func setupLandscapeConstraints() {
        let landscapeStackView = UIStackView()
        let rightStackView = UIStackView()
        let rightContainer = UIView()
        let insideContainer = UIView()
        let insideStackView = UIStackView()
        let buttonContainer = UIView()
        let textContainer = UIView()
        
        modalView.addSubview(landscapeStackView)
        
        insideContainer.backgroundColor = OEXStyles.shared().infoXXLight()
        
        textContainer.addSubview(celebrationMessageLabel)
        buttonContainer.addSubview(shareImageView)
        
        insideStackView.alignment = .fill
        insideStackView.axis = .horizontal
        insideStackView.distribution = .equalSpacing
        insideStackView.spacing = StandardHorizontalMargin / 2
        
        insideContainer.addSubview(insideStackView)
        insideStackView.addArrangedSubview(buttonContainer)
        insideStackView.addArrangedSubview(textContainer)
        insideContainer.addSubview(shareButtonView)
        
        shareButtonView.superview?.bringSubviewToFront(shareButtonView)
        
        landscapeStackView.alignment = .center
        landscapeStackView.axis = .horizontal
        landscapeStackView.distribution = .fillEqually
        landscapeStackView.spacing = StandardVerticalMargin * 2
        
        rightStackView.alignment = .fill
        rightStackView.axis = .vertical
        rightStackView.distribution = .equalSpacing
        rightStackView.spacing = StandardVerticalMargin
        
        rightStackView.addArrangedSubview(titleLabel)
        rightStackView.addArrangedSubview(titleMessageLabel)
        rightStackView.addArrangedSubview(insideContainer)
        rightStackView.addArrangedSubview(keepGoingButton)
        
        landscapeStackView.addArrangedSubview(congratulationImageView)
        landscapeStackView.addArrangedSubview(rightContainer)
        
        rightContainer.addSubview(rightStackView)
        
        rightStackView.snp.makeConstraints { make in
            make.edges.equalTo(rightContainer)
        }
        
        rightContainer.snp.remakeConstraints { make in
            make.height.equalTo(landscapeStackView)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(30)
        }
        
        titleMessageLabel.snp.remakeConstraints { make in
            make.height.equalTo(40)
        }
        
        insideContainer.snp.remakeConstraints { make in
            make.height.equalTo(80)
        }
        
        shareImageView.snp.remakeConstraints { make in
            make.height.equalTo(30)
            make.width.equalTo(26)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.top.equalTo(buttonContainer).offset(StandardVerticalMargin)
        }
        
        celebrationMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(textContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(textContainer)
            make.trailing.equalTo(textContainer)
        }
        
        insideStackView.snp.makeConstraints { make in
            make.top.equalTo(insideContainer)
            make.bottom.equalTo(insideContainer)
            make.trailing.equalTo(insideContainer).inset(20)
            make.leading.equalTo(insideContainer)
        }
        
        shareButtonView.snp.makeConstraints { make in
            make.edges.equalTo(insideContainer)
        }
        
        buttonContainer.snp.remakeConstraints { make in
            make.width.equalTo(80)
        }
        
        textContainer.snp.remakeConstraints { make in
            make.height.equalTo(insideStackView)
            make.leading.equalTo(buttonContainer.snp.trailing).inset(StandardHorizontalMargin / 2)
            make.trailing.equalTo(insideStackView).inset(StandardHorizontalMargin)
        }
        
        keepGoingButton.snp.remakeConstraints { (make) in
            make.height.equalTo(44)
        }
        
        modalView.snp.remakeConstraints { make in
            make.leading.equalTo(view).offset(40)
            make.trailing.equalTo(view).inset(40)
            make.top.equalTo(view).offset((view.frame.size.height / 4) / 2)
            make.bottom.equalTo(view).inset((view.frame.size.height / 4) / 2)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        
        landscapeStackView.snp.remakeConstraints { make in
            make.edges.equalTo(modalView).inset(20)
        }
    }
    
    @objc func orientationDidChanged() {
        setupViews()
    }
    
    private func shareCourse(courseID: String, courseURL: String, utmParameters: CourseShareUtmParameters) {
        guard let courseURL = NSURL(string: courseURL) else { return }
                
        let controller = shareHashtaggedTextAndALinka(textBuilder: { hashtagOrPlatform in
            Strings.shareACourse(platformName: hashtagOrPlatform)
        }, url: courseURL, utmParams: utmParameters, analyticsCallback: { [weak self] analyticsType in
            self?.environment.analytics.trackCourseCelebrationSocialShareClicked(courseID: courseID, type: analyticsType)
        })
        controller.configurePresentationController(withSourceView: shareImageView)
        present(controller, animated: true, completion: nil)
    }
}
