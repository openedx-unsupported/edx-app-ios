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
    func upgradeCourseAction(cell: CourseDashboardAccessErrorCell, course: OEXCourse, completion: @escaping ((Bool) -> ()) )
    func fetchCoursePrice(cell: CourseDashboardAccessErrorCell, completion: @escaping (String?, Bool) -> ())
}

class CourseDashboardAccessErrorCell: UITableViewCell {
    static let identifier = "CourseDashboardAccessErrorCell"
    
    weak var delegate: CourseDashboardAccessErrorCellDelegate?
    
    private lazy var infoMessagesView = ValuePropMessagesView()
    
    lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            guard let weakSelf = self, let course = self?.course else { return }
            self?.delegate?.upgradeCourseAction(cell: weakSelf, course: course) { [weak self] done in
                if done {
                    upgradeButton.isHidden = true
                    weakSelf.setConstraints(showValueProp: false, showUpgradeButton: false)
                } else {
                    weakSelf.setConstraints(showValueProp: true, showUpgradeButton: true)
                    upgradeButton.stopAnimating()
                }
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
        button.backgroundColor = .clear
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.findCourseAction()
        }, for: .touchUpInside)
        
        let style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().secondaryBaseColor())
        button.setAttributedTitle(style.attributedString(withText: Strings.CourseDashboard.Error.findANewCourse), for: UIControl.State())
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = true
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessibilityIdentifier = "CourseDashboardAccessErrorCell:view"
    }
    
    private var course: OEXCourse?
    private var coursePrice: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleCourseAccessError(_ error: CourseAccessError) {
        guard let title = error.errorTitle,
              let info = error.errorInfo else { return }
        
        let showValueProp = error.type == .auditExpired
        
        configureView(showValueProp: showValueProp)
        
        update(title: title, info: info)
        
        if showValueProp {
            upgradeButton.startShimeringEffect()
            delegate?.fetchCoursePrice(cell: self) { [weak self] price, error in
                self?.upgradeButton.stopShimmerEffect()
                
                if error {
                    self?.upgradeButton.isHidden = true
                    self?.setConstraints(showValueProp: showValueProp, showUpgradeButton: false)
                } else if let price = price {
                    self?.upgradeButton.setPrice(price)
                }
            }
        }
    }
    
    private func configureView(showValueProp: Bool = false) {
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(findCourseButton)
        
        setConstraints(showValueProp: showValueProp)
    }
    
    private func setConstraints(showValueProp: Bool = false, showUpgradeButton: Bool = true) {
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(2 * StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        infoLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2 * StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        var containerView: UIView = infoLabel
        var bottomOffset: CGFloat = 4
        
        if showValueProp {
            contentView.addSubview(infoMessagesView)
            
            infoMessagesView.snp.remakeConstraints { make in
                make.top.equalTo(infoLabel.snp.bottom).offset(2 * StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(infoMessagesView.height())
            }
            
            containerView = infoMessagesView
            
            if showUpgradeButton {
                contentView.addSubview(upgradeButton)
                
                upgradeButton.snp.remakeConstraints { make in
                    make.top.equalTo(infoMessagesView.snp.bottom).offset(4 * StandardVerticalMargin)
                    make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                    make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                    make.height.equalTo(StandardVerticalMargin * 4.5)
                }
                
                containerView = infoMessagesView
            }
                        
            bottomOffset = 2
        }
        
        findCourseButton.snp.remakeConstraints { make in
            make.top.equalTo(containerView.snp.bottom).offset(bottomOffset * StandardVerticalMargin)
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
}
