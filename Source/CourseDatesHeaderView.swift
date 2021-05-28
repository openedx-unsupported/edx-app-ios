//
//  CourseDatesHeaderView.swift
//  edX
//
//  Created by Muhammad Umer on 26/04/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol CourseDatesHeaderViewDelegate: AnyObject {
    func didToggleCalendarSwitch(isOn: Bool)
}

class CourseDatesHeaderView: UITableViewHeaderFooterView {
    
    typealias Delegate = CourseShiftDatesDelegate & CourseDatesHeaderViewDelegate
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    weak var delegate: Delegate?
    
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
    private var calendarSyncEnabled: Bool = false
    
    private var isButtonTextAvailable: Bool {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return false }
        return !status.button.isEmpty
    }
    
    private lazy var container = UIView()
    private lazy var topContainer = UIView()
    
    private let buttonMinWidth: CGFloat = 80
    private let buttonHeight: CGFloat = 40
    
    private let bottomContainer = UIView()
    
    private lazy var arrowImageView = UIImageView(image: Icon.DoubleArrow.imageWithFontSize(size: 24))
    private lazy var syncToCalenderLabel = UILabel()
    
    private lazy var syncSwitch: UISwitch = {
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
    
    private lazy var syncMessageTextStyle: OEXTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: styles.neutralXDark())
        style.alignment = .left
        return style
    }()
    
    var syncState: Bool = false {
        didSet {
            syncSwitch.isOn = syncState
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bottomContainer.addShadow(offset: CGSize(width: 0, height: 2), color: styles.primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 5)
    }
    
    func setupView(with bannerInfo: DatesBannerInfo, calendarSyncEnabled: Bool) {
        self.bannerInfo = bannerInfo
        self.calendarSyncEnabled = calendarSyncEnabled
        
        setupTopContainer()
        if calendarSyncEnabled {
            setupBottomContainer()
        }
        
        setAccessibilityIdentifiers()
    }
    
    private func setAccessibilityIdentifiers() {
        topContainer.accessibilityIdentifier = "CourseDatesHeaderView:top-container"
        bottomContainer.accessibilityIdentifier = "CourseDatesHeaderView:bottom-container"
        titleLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-course-schedule"
        descriptionLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-course-dates-description"
        shiftDatesButton.accessibilityIdentifier = "CourseDatesHeaderView:button-shift-dates"
        syncSwitch.accessibilityIdentifier = "CourseDatesHeaderView:switch-toggle-calendar-sync"
        syncMessageLabel.accessibilityIdentifier = "CourseDatesHeaderView:label-sync-message"
    }
    
    private func setupTopContainer() {
        addSubview(container)
        container.addSubview(topContainer)
        topContainer.addSubview(titleLabel)
        topContainer.addSubview(descriptionLabel)
        
        titleLabel.attributedText = titleTextStyle.attributedString(withText: Strings.Coursedates.courseSchedule)
        
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return }
        
        let attributedText = descriptionTextStyle.attributedString(withText: status.header + status.body)
        descriptionLabel.attributedText = attributedText.setLineSpacing(6)
        
        container.snp.remakeConstraints{ make in
            make.edges.equalTo(self)
        }
        
        topContainer.snp.remakeConstraints { make in
            make.top.equalTo(container)
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            if !calendarSyncEnabled {
                make.bottom.equalTo(container)
            }
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(topContainer).offset(StandardVerticalMargin)
            make.leading.equalTo(topContainer)
            make.trailing.equalTo(topContainer)
        }
        
        descriptionLabel.snp.remakeConstraints{make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            if !isButtonTextAvailable {
                make.bottom.equalTo(topContainer).inset(StandardVerticalMargin * 2)
            }
        }
        
        
        if isButtonTextAvailable {
            let buttonText = buttonStyle.attributedString(withText: status.button)
            shiftDatesButton.setAttributedTitle(buttonText, for: .normal)
            
            topContainer.addSubview(shiftDatesButton)
            
            shiftDatesButton.snp.makeConstraints { make in
                make.trailing.equalTo(topContainer).inset(StandardHorizontalMargin)
                make.top.equalTo(descriptionLabel.snp.bottom).offset(StandardVerticalMargin * 2)
                make.bottom.equalTo(topContainer).inset(StandardVerticalMargin * 2)
                make.width.greaterThanOrEqualTo(buttonMinWidth)
                make.height.equalTo(buttonHeight)
            }
        }
    }
    
    private func setupBottomContainer() {
        let syncContainer = UIView()
        syncContainer.backgroundColor = .white
        syncContainer.addSubview(arrowImageView)
        syncContainer.addSubview(syncToCalenderLabel)
        syncContainer.addSubview(syncSwitch)
        
        bottomContainer.addSubview(syncMessageLabel)
        bottomContainer.backgroundColor = .white
        bottomContainer.addSubview(syncContainer)
        container.addSubview(bottomContainer)
        
        syncToCalenderLabel.attributedText = syncToCalendarLabelTextStyle.attributedString(withText: Strings.Coursedates.syncToCalendar)
        let attributedText = syncMessageTextStyle.attributedString(withText: Strings.Coursedates.syncToCalendarMessage)
        syncMessageLabel.attributedText = attributedText.setLineSpacing(6)
        
        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom)
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.bottom.equalTo(container).inset(StandardVerticalMargin)
        }
        
        syncContainer.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin)
            make.height.equalTo(30)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin)
        }
        
        arrowImageView.snp.remakeConstraints { make in
            make.leading.equalTo(syncContainer)
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.centerY.equalTo(syncContainer)
        }
        
        syncToCalenderLabel.snp.remakeConstraints { make in
            make.leading.equalTo(arrowImageView.snp.trailing).offset(StandardHorizontalMargin/2)
            make.trailing.equalTo(syncSwitch.snp.leading).inset(StandardHorizontalMargin)
            make.centerY.equalTo(arrowImageView)
        }
        
        syncSwitch.snp.remakeConstraints { make in
            make.trailing.equalTo(syncContainer).inset(StandardHorizontalMargin * 1.2)
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.centerY.equalTo(syncContainer)
        }
        
        syncMessageLabel.snp.remakeConstraints { make in
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin)
            make.trailing.equalTo(syncSwitch.snp.leading)
            make.top.equalTo(syncContainer.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 1.5)
        }
    }
    
    @objc private func shiftButtonAction() {
        guard let bannerInfo = bannerInfo else { return }
        
        if bannerInfo.status == .resetDatesBanner {
            delegate?.courseShiftDateButtonAction()
        }
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
