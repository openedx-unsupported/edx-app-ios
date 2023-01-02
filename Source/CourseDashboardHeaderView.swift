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
    func didTapTabbarItem(at position: Int, tabbarItem: TabBarItem)
}

class CourseDashboardHeaderView: UITableViewHeaderFooterView {
    
    typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXConfigProvider & OEXStylesProvider & ServerConfigProvider & OEXSessionProvider & RemoteConfigProvider
    
    weak var delegate: CourseDashboardHeaderViewDelegate?
    
    private let imageSize: CGFloat = 20
    private let attributedIconOfset: CGFloat = -4
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    
    private lazy var containerView = UIView()
    private lazy var courseInfoContainerView = UIView()
    
    private lazy var orgLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseDashboardHeaderView:org-label"
        return label
    }()
    
    private lazy var courseTitle: UITextView = {
        let textView = UITextView()
        textView.accessibilityIdentifier = "CourseDashboardHeaderView:course-label"
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        let padding = textView.textContainer.lineFragmentPadding
        textView.textContainerInset =  UIEdgeInsets(top: 0, left: -padding, bottom: 0, right: -padding)
        
        let tapGesture = AttachmentTapGestureRecognizer { [weak self] _ in
            self?.delegate?.didTapOnShareCourse()
        }
        
        textView.addGestureRecognizer(tapGesture)
        
        return textView
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
        
        let lockedImage = Icon.Closed.imageWithFontSize(size: imageSize).image(with: environment.styles.neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: attributedIconOfset, width: image.size.width, height: image.size.height)
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
    
    private lazy var tabbarView: CourseDashboardTabbarView = {
        let tabbarView = CourseDashboardTabbarView(environment: environment, course: course)
        tabbarView.accessibilityIdentifier = "CourseDashboardHeaderView:tabbar-view"
        tabbarView.delegate = self
        return tabbarView
    }()
    
    private lazy var orgTextStyle = OEXTextStyle(weight: .bold, size: .small, color: environment.styles.accentBColor())
    
    private lazy var courseTextStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(textStyle: OEXTextStyle(weight: .bold, size: .xLarge, color: environment.styles.neutralWhiteT()))
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var accessTextStyle = OEXTextStyle(weight: .normal, size: .xSmall, color: environment.styles.neutralXLight())
        
    private var canShowValuePropView: Bool {
        guard let course = course,
              let enrollment = environment.interface?.enrollmentForCourse(withID: course.course_id)
        else { return false }
        
        if let error = error {
            if error.type == .auditExpired {
                return false
            }
        }
        return enrollment.type == .audit && environment.serverConfig.valuePropEnabled
    }
    
    private let environment: Environment
    private let course: OEXCourse?
    private let error: CourseAccessError?
    
    init(environment: Environment, course: OEXCourse?, error: CourseAccessError?) {
        self.environment = environment
        self.course = course
        self.error = error
        super.init(reuseIdentifier: nil)
        
        addSubViews()
        addConstraints()
        configureView()
    }
    
    private func configureView() {
        let courseTitleText = [
            courseTextStyle.attributedString(withText: course?.name),
            attributedUnicodeSpace,
            Icon.Share.attributedText(style: courseTextStyle, yOffset: attributedIconOfset)
        ]
        
        orgLabel.attributedText = orgTextStyle.attributedString(withText: course?.org)
        courseTitle.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: courseTitleText)
        accessLabel.attributedText = accessTextStyle.attributedString(withText: course?.nextRelevantDate)
    }
    
    private func addSubViews() {
        containerView.backgroundColor = environment.styles.primaryLightColor()
        closeButton.tintColor = environment.styles.neutralWhiteT()
        
        addSubview(containerView)
        containerView.addSubview(closeButton)
        containerView.addSubview(courseInfoContainerView)
        containerView.addSubview(tabbarView)
        
        courseInfoContainerView.addSubview(orgLabel)
        courseInfoContainerView.addSubview(courseTitle)
        courseInfoContainerView.addSubview(accessLabel)
    }
    
    private func addConstraints(hidetabbar: Bool = true) {
        containerView.snp.remakeConstraints { make in
            make.edges.equalTo(self)
        }
        
        closeButton.snp.remakeConstraints { make in
            make.top.equalTo(containerView).offset(StandardVerticalMargin * 2)
            make.trailing.equalTo(containerView).inset(StandardVerticalMargin * 2)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        courseInfoContainerView.snp.remakeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom)
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(containerView).inset(StandardHorizontalMargin)
        }
        
        orgLabel.snp.remakeConstraints { make in
            make.top.equalTo(courseInfoContainerView).offset(StandardVerticalMargin)
            make.leading.equalTo(courseInfoContainerView)
            make.trailing.equalTo(courseInfoContainerView)
        }
                
        courseTitle.snp.remakeConstraints { make in
            make.top.equalTo(orgLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(courseInfoContainerView)
            make.trailing.equalTo(courseInfoContainerView)
        }
        
        accessLabel.snp.remakeConstraints { make in
            make.top.equalTo(courseTitle.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(courseInfoContainerView)
            make.trailing.equalTo(courseInfoContainerView)
            make.bottom.equalTo(courseInfoContainerView).inset(StandardVerticalMargin)
        }
        
        var bottomContainer = courseInfoContainerView
        
        if canShowValuePropView {
            containerView.addSubview(valuePropView)
            
            valuePropView.snp.remakeConstraints { make in
                make.top.equalTo(bottomContainer.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(containerView).inset(StandardHorizontalMargin)
                make.height.equalTo(StandardVerticalMargin * 4.5)
            }
            
            bottomContainer = valuePropView
        }
                
        tabbarView.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.bottom.equalTo(containerView)
            make.height.equalTo(hidetabbar ? 0 : StandardVerticalMargin * 4.8)
        }
    }
    
    func showTabbarView(show: Bool) {
        addConstraints(hidetabbar: !show)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CourseDashboardHeaderView: CourseDashboardTabbarViewDelegate {
    func didSelectItem(at position: Int, tabbarItem: TabBarItem) {
        delegate?.didTapTabbarItem(at: position, tabbarItem: tabbarItem)
    }
}
