//
//  CourseDashboardAccessErrorCell.swift
//  edX
//
//  Created by Saeed Bashir on 12/2/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

enum CourseError {
    case isEndDateOld
    case startDateError
    case auditExpired
    case none
}

class CourseAccessError {
    private let course: OEXCourse?
    
    lazy var type: CourseError = {
        guard let course = course else { return .none }
        if course.isEndDateOld {
            return .isEndDateOld
        } else {
            guard let errorCode = course.courseware_access?.error_code else { return .none }
            switch errorCode {
            case .startDateError:
                return .startDateError
            case .auditExpired:
                return .auditExpired
                
            default:
                return .none
            }
        }
    }()
    
    init(course: OEXCourse?) {
        self.course = course
    }
    
    var errorTitle: String? {
        switch type {
        case .isEndDateOld:
            return Strings.CourseDashboard.Error.courseEndedTitle
        case .startDateError:
            return Strings.CourseDashboard.Error.courseNotStartedTitle
        case .auditExpired:
            return Strings.CourseDashboard.Error.courseAccessExpiredTitle
        default:
            return Strings.CourseDashboard.Error.courseAccessExpiredTitle
        }
    }
    
    var errorInfo: String? {
        guard let course = course else { return nil }
        
        switch type {
        case .isEndDateOld:
            return Strings.CourseDashboard.Error.courseAccessExpiredInfo
        case .startDateError:
            return formatedStartDate(displayInfo: course.start_display_info)
        case .auditExpired:
            return "Upgrade to get full access to this course and pursue a certificate."
        default:
            return Strings.CourseDashboard.Error.courseAccessExpiredInfo
        }
    }
    
    private func formatedStartDate(displayInfo: OEXCourseStartDisplayInfo) -> String {
        if let displayDate = displayInfo.displayDate, displayInfo.type == .string && !displayDate.isEmpty {
            return Strings.CourseDashboard.Error.courseNotStartedInfo(startDate: displayDate)
        }
        
        if let displayDate = displayInfo.date as? NSDate, displayInfo.type == .timestamp {
            let formattedDisplayDate = DateFormatting.format(asMonthDayYearString: displayDate) ?? ""
            return Strings.CourseDashboard.Error.courseNotStartedInfo(startDate: formattedDisplayDate)
        }
        
        return Strings.courseNotStarted
    }
}

protocol CourseDashboardAccessErrorCellDelegate: AnyObject {
    func findCourseAction()
    func upgradeCourseAction(course: OEXCourse)
    func fetchCoursePrice()
}

class CourseDashboardAccessErrorCell: UITableViewCell {
    static let identifier = "CourseDashboardAccessErrorCell"
    
    weak var delegate: CourseDashboardAccessErrorCellDelegate?
    
    private lazy var infoMessagesView = ValuePropMessagesView()
    
    lazy var upgradeButton: CourseUpgradeButtonView = {
        let upgradeButton = CourseUpgradeButtonView()
        upgradeButton.tapAction = { [weak self] in
            guard let course = self?.course else { return }
            self?.delegate?.upgradeCourseAction(course: course)
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
    
    func setCourseError(error: CourseAccessError) {
        guard let title = error.errorTitle,
              let info = error.errorInfo else { return }
        
        let showValueProp = error.type == .auditExpired
        
        configureView(showValueProp: showValueProp)
        
        update(title: title, info: info)
        
        if showValueProp {
            delegate?.fetchCoursePrice()
        }
    }
    
    private func configureView(showValueProp: Bool = false) {
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(findCourseButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(2 * StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2 * StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        var containerView: UIView = infoLabel
        var bottomOffset: CGFloat = 4
        
        if showValueProp {
            contentView.addSubview(infoMessagesView)
            contentView.addSubview(upgradeButton)
            
            infoMessagesView.snp.makeConstraints { make in
                make.top.equalTo(infoLabel.snp.bottom).offset(2 * StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.height.equalTo(infoMessagesView.height())
            }
            
            upgradeButton.snp.makeConstraints { make in
                make.top.equalTo(infoMessagesView.snp.bottom).offset(4 * StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            }
            
            containerView = upgradeButton
            bottomOffset = 2
        }
        
        findCourseButton.snp.makeConstraints { make in
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
