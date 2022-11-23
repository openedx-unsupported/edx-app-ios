//
//  CourseDashboardHeaderView.swift
//  edX
//
//  Created by MuhammadUmer on 15/11/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

protocol CourseDashboardHeaderViewDelegate: AnyObject {
    func didTapOnValueProp()
    func didTapOnClose()
    func didTapOnShareCourse()
}

class CourseDashboardHeaderView: UIView {
    
    typealias Environment = OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & ServerConfigProvider
    
    private let imageSize: CGFloat = 20
    private let styles = OEXStyles.shared()
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    
    private lazy var container = UIView()
    private lazy var titleContainer = UIView()
    
    private lazy var orgTitle = UILabel()
    private lazy var courseTitle = UILabel()
    private lazy var courseAccessTitle = UILabel()
    
    weak var delegate: CourseDashboardHeaderViewDelegate?
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        let image = Icon.Close.imageWithFontSize(size: imageSize)
        closeButton.setImage(image, for: .normal)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        
        closeButton.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnClose()
        }, for: .touchUpInside)
        
        return closeButton
    }()
    
    private lazy var valuePropView: UIView = {
        let valuePropView = UIView()
        
        valuePropView.backgroundColor = environment.styles.standardBackgroundColor()
        
        let lockedImage = Icon.Closed.imageWithFontSize(size: imageSize).image(with: OEXStyles.shared().neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: -4, width: image.size.width, height: image.size.height)
        }
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight: .semiBold, size: .base, color: environment.styles.neutralWhiteT())
        
        let attributedStrings = [
            attributedImageString,
            attributedUnicodeSpace,
            style.attributedString(withText: Strings.ValueProp.courseDashboardButtonTitle)
        ]
        
        let attributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnValueProp()
        }, for: .touchUpInside)
        
        button.backgroundColor = environment.styles.secondaryDarkColor()
        button.setAttributedTitle(attributedTitle, for: .normal)
        valuePropView.addSubview(button)
        
        button.snp.remakeConstraints { make in
            make.edges.equalTo(valuePropView)
        }
        
        return valuePropView
    }()
    
    private lazy var orgTitleTextStyle = OEXTextStyle(weight: .bold, size: .small, color: styles.accentBColor())
    private lazy var courseTitleTextStyle = OEXTextStyle(weight: .bold, size: .xLarge, color: styles.neutralWhiteT())
    private lazy var courseAccessTitleTextStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: styles.neutralXLight())
    
    private var canShowValuePropView: Bool {
        guard let course = course,
              let enrollment = environment.interface?.enrollmentForCourse(withID: course.course_id) else { return false }
        return enrollment.type == .audit && environment.serverConfig.valuePropEnabled
    }
    
    private let course: OEXCourse?
    private let environment: Environment
    
    init(course: OEXCourse?, environment: Environment) {
        self.course = course
        self.environment = environment
        super.init(frame: .zero)
        
        addSubViews()
        addConstraints()
    }
    
    private func addSubViews() {
        container.backgroundColor = styles.primaryLightColor()
        closeButton.tintColor = styles.neutralWhiteT()
        courseTitle.numberOfLines = 0
        
        addSubview(container)
        container.addSubview(closeButton)
        container.addSubview(titleContainer)
        
        titleContainer.addSubview(orgTitle)
        titleContainer.addSubview(courseTitle)
        titleContainer.addSubview(courseAccessTitle)
        
        orgTitle.attributedText = orgTitleTextStyle.attributedString(withText: course?.org)
        let courseTitleText = [
            courseTitleTextStyle.attributedString(withText: course?.name),
            attributedUnicodeSpace,
            Icon.Share.attributedTextWithStyle(style: courseTitleTextStyle)
        ]
        courseTitle.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: courseTitleText)
        courseTitle.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction { [weak self] gesture in
            self?.courseTitleTap(gesture: gesture)
        }
        courseTitle.addGestureRecognizer(tapGesture)
        courseAccessTitle.attributedText = courseAccessTitleTextStyle.attributedString(withText: course?.nextRelevantDate)
    }
    
    private func addConstraints() {
        orgTitle.snp.makeConstraints { make in
            make.top.equalTo(titleContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
        }
        
        courseTitle.snp.makeConstraints { make in
            make.top.equalTo(orgTitle.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
        }
        
        courseAccessTitle.snp.makeConstraints { make in
            make.top.equalTo(courseTitle.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin * 2)
            make.trailing.equalTo(container).inset(StandardVerticalMargin * 2)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            make.top.equalTo(closeButton.snp.bottom)
            make.bottom.equalTo(courseAccessTitle).offset(StandardVerticalMargin)
        }
        
        var bottomContainer = titleContainer
        
        if canShowValuePropView {
            container.addSubview(valuePropView)
            
            valuePropView.snp.makeConstraints { make in
                make.top.equalTo(titleContainer.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
                make.trailing.equalTo(self).inset(StandardHorizontalMargin)
                make.height.equalTo(StandardVerticalMargin * 4.5)
            }
            
            bottomContainer = valuePropView
        }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(bottomContainer.snp.bottom).offset(StandardVerticalMargin * 2)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func courseTitleTap(gesture: UITapGestureRecognizer) {
        if gesture.didTapAttributedTextInLabel(label: courseTitle) {
            delegate?.didTapOnShareCourse()
        }
    }
}

fileprivate extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel) -> Bool {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        let locationOfTouchInLabel = location(in: label)
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < textStorage.length {
            let attachment = label.attributedText?.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment
            if attachment != nil {
                return true
            }
        }
        return false
    }
}
