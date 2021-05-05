//
//  CourseDatesHeaderView.swift
//  edX
//
//  Created by Muhammad Umer on 26/04/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol CourseDatesHeaderViewDelegate {
    func didToggleCalendarSwitch(isOn: Bool)
}

class CourseDatesHeaderView: UIView {
    
    typealias Delegate = CourseShiftDatesDelegate & CourseDatesHeaderViewDelegate
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var delegate: Delegate?
    
    private let stackView: TZStackView = {
        let stackView = TZStackView()
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var styles = OEXStyles.shared()
    
    private lazy var titleTextStyle: OEXTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .xLarge, color: styles.primaryDarkColor())
        style.alignment = .left
        return style
    }()
    
    private lazy var descriptionTextStyle: OEXTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: styles.neutralXDark())
        style.alignment = .left
        return style
    }()
    
    private lazy var buttonStyle = OEXMutableTextStyle(weight: .semiBold, size: .base, color: styles.neutralWhiteT())
    
    private lazy var titleLabel = UILabel()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var buttonContainer = UIView()
    
    private lazy var shiftDatesButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.layer.backgroundColor = styles.primaryBaseColor().cgColor
        button.layer.borderColor = styles.primaryBaseColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 0
        button.oex_removeAllActions()
        button.oex_addAction({ [weak self] _ in
            self?.shiftButtonAction()
        }, for: .touchUpInside)
        return button
    }()
    
    private var bannerInfo: DatesBannerInfo?
    private var isSelfPaced: Bool = false
    
    private var isButtonTextAvailable: Bool {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return false }
        return !status.button.isEmpty
    }
    
    private lazy var topContainer = UIView()
    
    private let buttonMinWidth: CGFloat = 80
    private let buttonContainerHeight: CGFloat = 40
    
    private let bottomContainer = UIView()
    
    private lazy var arrowImageView = UIImageView(image: Icon.DoubleArrow.imageWithFontSize(size: 24))
    private lazy var syncToCalenderLabel = UILabel()
    private lazy var calenderSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.oex_addAction({ [weak self] _ in
            self?.delegate?.didToggleCalendarSwitch(isOn: toggleSwitch.isOn)
        }, for: .valueChanged)
        
        return toggleSwitch
    }()
    
    private lazy var syncMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var syncToCalendarLabelTextStyle: OEXTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .base, color: styles.primaryDarkColor())
        style.alignment = .left
        return style
    }()
    
    private lazy var syncMessageLabelTextStyle: OEXTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: styles.neutralXDark())
        style.alignment = .left
        return style
    }()
    
    var switchIsOn: Bool = false {
        didSet {
            calenderSwitch.isOn = switchIsOn
        }
    }
    
    private var estimatedTopContainerHeight: Int {
        return estimatedHeightForTitleLabel + estimatedHeightForMessageLabel + estimatedButtonHeight
    }
    
    private var estimatedBottomContainerHeight: Int {
        return estimatedHeightForCalendarMessageLabel + estimatedHeightForSwitchContainer + (Int(StandardVerticalMargin) * 2)
    }
    
    var estimatedHeight: Int {
        return isSelfPaced ? estimatedTopContainerHeight + estimatedBottomContainerHeight : estimatedTopContainerHeight
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bottomContainer.addShadow(offset: CGSize(width: 0, height: 2), color: styles.primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 5)
    }
    
    func setupView(with bannerInfo: DatesBannerInfo, isSelfPaced: Bool) {
        self.bannerInfo = bannerInfo
        self.isSelfPaced = isSelfPaced
        
        setupTopContainer()
        if isSelfPaced {
            setupBottomContainer()
        }
        
        setAccessibilityIdentifiers()
    }
    
    private func setAccessibilityIdentifiers() {
        titleLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-course-schedule"
        descriptionLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-course-dates-description"
        shiftDatesButton.accessibilityIdentifier = "CourseDatesHeaderView:button-shift-dates"
        calenderSwitch.accessibilityIdentifier = "CourseDatesHeaderView:switch-toggle-calendar-sync"
        syncMessageLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-sync-message"
    }
    
    private func setupBottomContainer() {
        let container = UIView()
        
        container.addSubview(arrowImageView)
        container.addSubview(syncToCalenderLabel)
        container.addSubview(calenderSwitch)
        
        bottomContainer.addSubview(syncMessageLabel)
        
        bottomContainer.backgroundColor = .white
        container.backgroundColor = .white
        bottomContainer.addSubview(container)
        addSubview(bottomContainer)
        
        syncToCalenderLabel.attributedText = syncToCalendarLabelTextStyle.attributedString(withText: Strings.Coursedates.syncToCalendar)
        
        let attributedText = syncMessageLabelTextStyle.attributedString(withText: Strings.Coursedates.syncToCalendarMessage)
        
        syncMessageLabel.attributedText = attributedText.setLineSpacing(6)
        
        arrowImageView.snp.remakeConstraints { make in
            make.leading.equalTo(container)
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.centerY.equalTo(container)
        }
        
        syncToCalenderLabel.snp.remakeConstraints { make in
            make.leading.equalTo(arrowImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(calenderSwitch.snp.leading)
            make.top.equalTo(container)
            make.bottom.equalTo(container)
        }
        
        calenderSwitch.snp.remakeConstraints { make in
            make.trailing.equalTo(container)
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.centerY.equalTo(container)
        }
        
        container.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin)
            make.height.equalTo(30)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
        }
        
        syncMessageLabel.snp.remakeConstraints { make in
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.top.equalTo(container.snp.bottom).offset(StandardVerticalMargin)
        }
        
        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(syncMessageLabel).offset(StandardVerticalMargin * 1.5)
        }
    }
    
    private func setupTopContainer() {
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        topContainer.addSubview(stackView)
        
        titleLabel.attributedText = titleTextStyle.attributedString(withText: Strings.Coursedates.courseSchedule)
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return }
        let attributedText = descriptionTextStyle.attributedString(withText: status.header + status.body)
        descriptionLabel.attributedText = attributedText.setLineSpacing(6)
        
        addSubview(topContainer)
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(30)
        }
        
        stackView.snp.remakeConstraints { make in
            make.edges.equalTo(topContainer)
        }
        
        topContainer.snp.remakeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(estimatedTopContainerHeight)
        }
        
        if isButtonTextAvailable {
            let buttonText = buttonStyle.attributedString(withText: status.button)
            shiftDatesButton.setAttributedTitle(buttonText, for: .normal)
            
            stackView.addArrangedSubview(buttonContainer)
            buttonContainer.addSubview(shiftDatesButton)
            
            buttonContainer.snp.makeConstraints { make in
                make.height.equalTo(buttonContainerHeight)
                make.width.equalTo(stackView)
                make.bottom.equalTo(stackView)
            }
            
            shiftDatesButton.snp.makeConstraints { make in
                make.trailing.equalTo(buttonContainer)
                make.top.equalTo(buttonContainer)
                make.bottom.equalTo(buttonContainer)
                make.width.greaterThanOrEqualTo(buttonMinWidth)
            }
        }
    }
    
    @objc private func shiftButtonAction() {
        guard let bannerInfo = bannerInfo else { return }
        
        if bannerInfo.status == .resetDatesBanner {
            delegate?.courseShiftDateButtonAction()
        }
    }
    
    private var estimatedHeightForTitleLabel: Int {
        let widthOffset = StandardHorizontalMargin * 2
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width - widthOffset, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Coursedates.courseSchedule)
        label.sizeToFit()
        
        return Int(label.frame.height + StandardVerticalMargin)
    }
    
    private var estimatedHeightForMessageLabel: Int {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return 0 }
        let attributedText = descriptionTextStyle.attributedString(withText: status.header + status.body)
        let widthOffset = StandardHorizontalMargin * 2
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width - widthOffset, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedText = attributedText.setLineSpacing(6)
        label.sizeToFit()
        
        return Int(label.frame.height + StandardVerticalMargin)
    }
    
    private var estimatedButtonHeight: Int {
        return Int(isButtonTextAvailable ? buttonContainerHeight : 0)
    }
    
    private var estimatedHeightForSwitchContainer: Int {
        return 30
    }
    
    private var estimatedHeightForCalendarMessageLabel: Int {
        let attributedText = syncMessageLabelTextStyle.attributedString(withText: Strings.Coursedates.syncToCalendarMessage)
        let widthOffset = StandardHorizontalMargin * 2
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: frame.size.width - widthOffset, height: .greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedText = attributedText.setLineSpacing(6)
        label.sizeToFit()
        
        return Int(label.frame.height + StandardVerticalMargin)
    }
}

fileprivate extension UIView {
    func addShadow(offset: CGSize, color: UIColor, radius: CGFloat, opacity: Float, cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false
        layer.shadowOffset = offset
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        let backgroundCGColor = backgroundColor?.cgColor
        backgroundColor = nil
        layer.backgroundColor = backgroundCGColor
    }
}
