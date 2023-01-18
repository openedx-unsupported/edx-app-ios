//
//  CourseDashboardAccessErrorCell.swift
//  edX
//
//  Created by Saeed Bashir on 12/2/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

protocol CourseDashboardAccessErrorCellDelegate: AnyObject {
    func findCourseAction()
    func upgradeCourseAction(course: OEXCourse, completion: @escaping ((Bool)->()))
}

class CourseDashboardAccessErrorCell: UITableViewCell {
    static let identifier = "CourseDashboardAccessErrorCell"
    
    weak var delegate: CourseDashboardAccessErrorCellDelegate?
    
    private lazy var infoMessagesView = ValuePropMessagesView()
    
    private lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            guard let course = self?.course, let error = self?.error else { return }
            self?.delegate?.upgradeCourseAction(course: course) { _ in
                self?.upgradeButton.stopAnimating()
            }
        }
        return upgradeButton
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityIdentifier = "CourseDashboardAccessErrorCell:title-label"
        return label
    }()
    
    private var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityIdentifier = "CourseDashboardAccessErrorCell:info-label"
        return label
    }()
    
    private lazy var findCourseButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = "CourseDashboardAccessErrorCell:findcourse-button"
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.findCourseAction()
        }, for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessibilityIdentifier = "CourseDashboardAccessErrorCell:view"
    }
    
    private var containerView: UIView?
    private var bottomOffset: CGFloat = 4
    
    private var course: OEXCourse?
    private var error: CourseAccessErrorHelper?
    
    var coursePrice: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleCourseAccessError(course: OEXCourse?, error: CourseAccessErrorHelper) {
        guard let course = course else { return }
        
        self.course = course
        self.error = error
        
        guard let title = error.errorTitle,
              let info = error.errorInfo else { return }
        
        let showValueProp = error.shouldShowValueProp
        configureViews()
        update(title: title, info: info)
        
        if showValueProp {
            if course.sku == nil {
                setConstraints(showValueProp: showValueProp, showUpgradeButton: false)
            } else {
                setConstraints(showValueProp: showValueProp, showUpgradeButton: true)
                if let coursePrice = coursePrice {
                    upgradeButton.stopShimmerEffect()
                    upgradeButton.setPrice(coursePrice)
                } else {
                    upgradeButton.startShimeringEffect()
                }
            }
        } else {
            setConstraints(showValueProp: false, showUpgradeButton: false)
        }
    }
    
    private func configureViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(infoMessagesView)
        contentView.addSubview(upgradeButton)
        contentView.addSubview(findCourseButton)
    }
    
    private func setConstraints(showValueProp: Bool, showUpgradeButton: Bool) {
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        infoLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2 * StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        containerView = infoLabel
        
        if showValueProp {
            infoMessagesView.snp.remakeConstraints { make in
                make.top.equalTo(infoLabel.snp.bottom).offset(StandardVerticalMargin * 2)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(infoMessagesView.height())
            }
            
            containerView = infoMessagesView
        }
        
        if showUpgradeButton {
            applyStyle(to: findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse, light: true)
            
            upgradeButton.isHidden = false
            upgradeButton.snp.remakeConstraints { make in
                make.top.equalTo(infoMessagesView.snp.bottom).offset(StandardVerticalMargin * 5)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(upgradeButton.height)
            }
            
            containerView = upgradeButton
            bottomOffset = 2
        } else {
            applyStyle(to: findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse, light: false)
            upgradeButton.isHidden = true
        }
        
        guard let containerView = containerView else { return }
        
        findCourseButton.snp.remakeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(StandardVerticalMargin * bottomOffset)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.bottom.equalTo(contentView)
        }
    }
    
    private func update(title: String, info: String) {
        let titleTextStyle = OEXTextStyle(weight: .bold, size: .xLarge, color: OEXStyles.shared().neutralBlackT())
        let infoTextStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        infoLabel.attributedText = infoTextStyle.attributedString(withText: info)
    }
    
    private func applyStyle(to button: UIButton, text: String, light: Bool) {
        let style: OEXTextStyle
        let backgroundColor: UIColor
        let borderWidth: CGFloat
        let borderColor: UIColor

        if light {
            style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().secondaryBaseColor())
            backgroundColor = .clear
            borderWidth = 1
            borderColor = OEXStyles.shared().neutralXLight()
        } else {
            style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhiteT())
            backgroundColor = OEXStyles.shared().secondaryBaseColor()
            borderWidth = 0
            borderColor = .clear
        }
        
        button.setAttributedTitle(style.attributedString(withText: text), for: UIControl.State())
        button.backgroundColor = backgroundColor
        button.layer.borderWidth = borderWidth
        button.layer.borderColor = borderColor.cgColor
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = true
    }
}
