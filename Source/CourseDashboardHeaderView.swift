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

class CourseDashboardHeaderView: UITableViewHeaderFooterView {
    
    typealias Environment = OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & ServerConfigProvider
    
    weak var delegate: CourseDashboardHeaderViewDelegate?
    
    private let imageSize: CGFloat = 20
    private let styles = OEXStyles.shared()
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    
    private lazy var container = UIView()
    private lazy var titleContainer = UIView()
    
    private lazy var orgLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseDashboardHeaderView:org-label"
        return label
    }()
    
    private lazy var courseLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseDashboardHeaderView:course-label"
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction { [weak self] gesture in
            self?.courseTitleTap(gesture: gesture)
        }
        
        label.addGestureRecognizer(tapGesture)
        
        return label
    }()
    
    private lazy var accessLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseDashboardHeaderView:course-access-label"
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "CourseDashboardHeaderView:close-button"
        button.setImage(Icon.Close.imageWithFontSize(size: imageSize), for: .normal)
        button.accessibilityLabel = Strings.Accessibility.closeLabel
        button.accessibilityHint = Strings.Accessibility.closeHint
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnClose()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var valuePropView: UIView = {
        let valuePropView = UIView()
        valuePropView.accessibilityIdentifier = "CourseDashboardHeaderView:value-prop-view"
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
    
    private lazy var orgTextStyle = OEXTextStyle(weight: .bold, size: .small, color: styles.accentBColor())
    private lazy var courseTextStyle = OEXTextStyle(weight: .bold, size: .xLarge, color: styles.neutralWhiteT())
    private lazy var accessTextStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: styles.neutralXLight())
    
    private var canShowValuePropView: Bool {
        guard let course = course,
              let enrollment = environment.interface?.enrollmentForCourse(withID: course.course_id)
        else { return false }
        return enrollment.type == .audit && environment.serverConfig.valuePropEnabled
    }
    
    private let course: OEXCourse?
    private let environment: Environment
    
    init(course: OEXCourse?, environment: Environment) {
        self.course = course
        self.environment = environment
        super.init(reuseIdentifier: nil)
        
        addSubViews()
        addConstraints()
    }
    
    private func addSubViews() {
        container.backgroundColor = styles.primaryLightColor()
        closeButton.tintColor = styles.neutralWhiteT()
        
        addSubview(container)
        container.addSubview(closeButton)
        container.addSubview(titleContainer)
        
        titleContainer.addSubview(orgLabel)
        titleContainer.addSubview(courseLabel)
        titleContainer.addSubview(accessLabel)
        
        let courseTitleText = [
            courseTextStyle.attributedString(withText: course?.name),
            attributedUnicodeSpace,
            Icon.Share.attributedText(style: courseTextStyle, yOffset: -4)
        ]
        
        orgLabel.attributedText = orgTextStyle.attributedString(withText: course?.org)
        courseLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: courseTitleText)
        accessLabel.attributedText = accessTextStyle.attributedString(withText: course?.nextRelevantDate)
    }
    
    private func addConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin * 2)
            make.trailing.equalTo(container).inset(StandardVerticalMargin * 2)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
        }
        
        orgLabel.snp.makeConstraints { make in
            make.top.equalTo(titleContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
        }
        
        courseLabel.snp.makeConstraints { make in
            make.top.equalTo(orgLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
        }
        
        accessLabel.snp.makeConstraints { make in
            make.top.equalTo(courseLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(titleContainer)
            make.trailing.equalTo(titleContainer)
            make.bottom.equalTo(titleContainer).inset(StandardVerticalMargin)
        }
        
        var bottomContainer = titleContainer
        
        if canShowValuePropView {
            container.addSubview(valuePropView)
            
            valuePropView.snp.makeConstraints { make in
                make.top.equalTo(bottomContainer.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(container).offset(StandardHorizontalMargin)
                make.trailing.equalTo(container).inset(StandardHorizontalMargin)
                make.height.equalTo(StandardVerticalMargin * 4.5)
            }
            
            bottomContainer = valuePropView
        }
        
        bottomContainer.snp.makeConstraints { make in
            make.bottom.equalTo(container).inset(StandardVerticalMargin * 2)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func courseTitleTap(gesture: UITapGestureRecognizer) {
        if gesture.didTapOnAttachment(in: courseLabel) {
            delegate?.didTapOnShareCourse()
        }
    }
}

fileprivate extension UITapGestureRecognizer {
    func didTapOnAttachment(in label: UILabel) -> Bool {
        guard let attributedText = label.attributedText else { return false }
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        let locationOfTouchInLabel = location(in: label)
        let characterIndex = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if characterIndex < textStorage.length,
           let _ = label.attributedText?.attribute(.attachment, at: characterIndex, effectiveRange: nil) as? NSTextAttachment {
            return true
        }
        return false
    }
}
