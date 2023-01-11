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
    func fetchCoursePrice(cell: CourseDashboardAccessErrorCell, completion: @escaping (String?) -> ())
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
                upgradeButton.stopAnimating()
                weakSelf.addBottomView(showValueProp: !done, showUpgradeButton: !done)
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
    private var coursePrice: String?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handleCourseAccessError(_ error: CourseAccessErrorHelper) {
        guard let title = error.errorTitle,
              let info = error.errorInfo else { return }
        
        let showValueProp = error.shouldShowValueProp
        configureView(showValueProp: showValueProp)
        update(title: title, info: info)
        
        if showValueProp {
            upgradeButton.startShimeringEffect()
            delegate?.fetchCoursePrice(cell: self) { [weak self] price in
                self?.upgradeButton.stopShimmerEffect()
                if let price = price {
                    self?.upgradeButton.setPrice(price)
                } else {
                    self?.upgradeButton.isHidden = true
                    self?.addBottomView(showValueProp: showValueProp, showUpgradeButton: false)
                }
            }
        }
    }
    
    private func configureView(showValueProp: Bool = false) {
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        
        setConstraints(showValueProp: showValueProp)
    }
    
    private func setConstraints(showValueProp: Bool = false, showUpgradeButton: Bool = true) {
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
    }
    
    private func addBottomView(showValueProp: Bool, showUpgradeButton: Bool) {
        if showValueProp {
            contentView.addSubview(infoMessagesView)
            
            infoMessagesView.snp.remakeConstraints { make in
                make.top.equalTo(infoLabel.snp.bottom).offset(StandardVerticalMargin * 2)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(infoMessagesView.height())
            }
            
            containerView = infoMessagesView
            
            if showUpgradeButton {
                contentView.addSubview(upgradeButton)
                
                upgradeButton.snp.remakeConstraints { make in
                    make.top.equalTo(infoMessagesView.snp.bottom).offset(StandardVerticalMargin * bottomOffset)
                    make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                    make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                    make.height.equalTo(StandardVerticalMargin * 4.5)
                }
                
                containerView = upgradeButton
                bottomOffset = 2
            }
        }
        
        contentView.addSubview(findCourseButton)
        
        guard let containerView = containerView else { return }
        
        if showUpgradeButton {
            applyLightStyle(findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse)
        } else {
            applyDarkStyle(findCourseButton, text: Strings.CourseDashboard.Error.findANewCourse)
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
    
    private func applyLightStyle(_ button: UIButton, text: String) {
        let style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().secondaryBaseColor())
        button.setAttributedTitle(style.attributedString(withText: Strings.CourseDashboard.Error.findANewCourse), for: UIControl.State())
        
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = true
    }
    
    private func applyDarkStyle(_ button: UIButton, text: String) {
        let style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhiteT())
        button.setAttributedTitle(style.attributedString(withText: Strings.CourseDashboard.Error.findANewCourse), for: UIControl.State())
        
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        button.layer.borderWidth = 0
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = true
    }
}
