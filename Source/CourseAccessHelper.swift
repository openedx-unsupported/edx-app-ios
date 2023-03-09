//
//  CourseAccessHelper.swift
//  edX
//
//  Created by MuhammadUmer on 05/01/2023.
//  Copyright © 2023 edX. All rights reserved.
//

enum CourseAccessErrorHelperType {
    case isEndDateOld
    case startDateError
    case auditExpired
    case upgradeable
}

class CourseAccessHelper {
    private let course: OEXCourse
    private let enrollment: UserCourseEnrollment?
    
    init(course: OEXCourse, enrollment: UserCourseEnrollment? = nil) {
        self.course = course
        self.enrollment = enrollment
    }
    
    var type: CourseAccessErrorHelperType? {
        guard let enrollment = enrollment else { return nil }
        
        if course.isEndDateOld {
            if enrollment.isUpgradeable {
                return .upgradeable
            } else {
                return .isEndDateOld
            }
        } else {
            guard let errorCode = course.courseware_access?.error_code else { return nil }
            
            switch errorCode {
            case .startDateError:
                return .startDateError
            case .auditExpired:
                return .auditExpired
            
            default:
                return nil
            }
        }
    }
    
    var shouldShowValueProp: Bool {
        return type == .upgradeable || type == .auditExpired
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
        switch type {
        case .isEndDateOld:
            return Strings.CourseDashboard.Error.courseAccessExpiredInfo
        case .startDateError:
            return formatedStartDate(displayInfo: course.start_display_info)
        case .auditExpired:
            return Strings.CourseDashboard.Error.auditExpiredUpgradeInfo
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
