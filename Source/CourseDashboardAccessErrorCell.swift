//
//  CourseDashboardAccessErrorCell.swift
//  edX
//
//  Created by Saeed Bashir on 12/2/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

class CourseDashboardAccessErrorCell: UITableViewCell {
    static let identifier = "CourseDashboardAccessErrorCell"

    var findCourseAction: (() -> Void)?

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
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        button.oex_addAction({ [weak self] _ in
            self?.findCourseAction?()
        }, for: .touchUpInside)

        let style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhite())
        button.setAttributedTitle(style.attributedString(withText: Strings.CourseDashboard.Error.findANewCourse), for: UIControl.State())

        return button
    }()

    private var titleTextStyle: OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .xLarge, color: OEXStyles.shared().neutralBlackT())
    }

    private var infoTextStyle: OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }

    private var findCourseButtonTextStyle: OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().secondaryBaseColor())
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        accessibilityIdentifier = "CourseDashboardAccessErrorCell:view"

        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
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
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }

        findCourseButton.snp.makeConstraints { make in
            make.top.equalTo(infoLabel.snp.bottom).offset(4 * StandardVerticalMargin)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.bottom.equalTo(contentView)
        }
    }

    func setError(course: OEXCourse?) {
        guard let course = course, let access = course.courseware_access else { return }

        var title = ""
        var info = ""

        if course.isEndDateOld {
            title = Strings.CourseDashboard.Error.courseEndedTitle
            info = Strings.CourseDashboard.Error.courseAccessExpiredInfo
        }
        else {
            switch access.error_code {
            case .startDateError:
                title = Strings.CourseDashboard.Error.courseNotStartedTitle
                info = formatedStartDate(displayInfo: course.start_display_info)
            case .auditExpired:
                title = Strings.CourseDashboard.Error.courseAccessExpiredTitle
                info = Strings.CourseDashboard.Error.courseAccessExpiredInfo
            default:
                title = Strings.CourseDashboard.Error.courseAccessExpiredTitle
                info = Strings.CourseDashboard.Error.courseAccessExpiredInfo
                break
            }
        }

        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        infoLabel.attributedText = infoTextStyle.attributedString(withText: info)
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
