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
    func upgradeCourseAction(course: OEXCourse, price: String?, completion: @escaping ((Bool)->()))
    func coursePrice(cell: CourseDashboardAccessErrorCell, price: String?, elapsedTime: Int)
}

class CourseDashboardAccessErrorCell: UITableViewCell {
    static let identifier = "CourseDashboardAccessErrorCell"
    
    typealias Environment = OEXConfigProvider & ServerConfigProvider
    weak var delegate: CourseDashboardAccessErrorCellDelegate?
    
    private lazy var infoMessagesView = ValuePropMessagesView()
    private var environment: Environment?
    
    private lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            guard let course = self?.course else { return }
            self?.delegate?.upgradeCourseAction(course: course, price: self?.coursePrice) { _ in
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
    
    private lazy var hiddenView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "CourseDashboardAccessErrorCell:hidden-view"
        view.backgroundColor = .clear
        
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessibilityIdentifier = "CourseDashboardAccessErrorCell:view"
    }
    
    private var course: OEXCourse?
    private var error: CourseAccessErrorHelper?
    
    var coursePrice: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleCourseAccessError(environment: Environment, course: OEXCourse?, error: CourseAccessErrorHelper?) {
        guard let course = course else { return }
        
        self.course = course
        self.error = error
        self.environment = environment
        
        guard let title = error?.errorTitle,
              let info = error?.errorInfo else { return }
        
        let showValueProp = error?.shouldShowValueProp ?? false
        configureViews()
        update(title: title, info: info)
        
        if course.sku != nil {
            setConstraints(showValueProp: showValueProp, showUpgradeButton: true)
            fetchCoursePrice()
        }
        else {
            setConstraints(showValueProp: showValueProp, showUpgradeButton: false)
        }
    }
    
    private func configureViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(infoMessagesView)
        contentView.addSubview(upgradeButton)
        contentView.addSubview(findCourseButton)
        contentView.addSubview(hiddenView)
    }
    
    func hideUpgradeButton() {
        setConstraints(showValueProp: error?.shouldShowValueProp ?? false, showUpgradeButton: false)
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
        
        var lastView: UIView
        lastView = infoLabel
        
        if showValueProp {
            infoMessagesView.snp.remakeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(StandardVerticalMargin * 2)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(infoMessagesView.height())
            }
            
            lastView = infoMessagesView
        }
        
        if showUpgradeButton {
            applyStyle(to: findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse, light: true)
            
            upgradeButton.isHidden = false
            upgradeButton.snp.remakeConstraints { make in
                make.top.equalTo(lastView.snp.bottom).offset(StandardVerticalMargin * 5)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(StandardVerticalMargin * 5.5)
            }
            
            lastView = upgradeButton
        } else {
            applyStyle(to: findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse, light: false)
            upgradeButton.isHidden = true
            upgradeButton.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }
        
        findCourseButton.snp.remakeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5.5)
        }
        
        hiddenView.snp.remakeConstraints { make in
            make.top.equalTo(findCourseButton.snp.bottom)
            make.bottom.equalTo(contentView).offset(1)
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
    
    func fetchCoursePrice() {
        guard let courseSku = course?.sku, environment?.serverConfig.iapConfig?.enabledforUser == true else { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.async { [weak self] in
            self?.upgradeButton.startShimeringEffect()
            PaymentManager.shared.productPrice(courseSku) { [weak self] price in
                guard let self else { return }
                
                if let price = price {
                    let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
                    self.coursePrice = price
                    self.delegate?.coursePrice(cell: self, price: price, elapsedTime: elapsedTime.millisecond)
                    self.upgradeButton.setPrice(price)
                    self.upgradeButton.stopShimmerEffect()
                }
                else {
                    self.delegate?.coursePrice(cell: self, price: nil, elapsedTime: 0)
                }
            }
        }
    }
}
