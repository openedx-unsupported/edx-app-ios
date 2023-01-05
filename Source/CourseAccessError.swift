//
//  CourseAccessError.swift
//  edX
//
//  Created by MuhammadUmer on 05/01/2023.
//  Copyright © 2023 edX. All rights reserved.
//

enum CourseAccessErrorType {
    case isEndDateOld
    case startDateError
    case auditExpired
    case none
}

class CourseAccessError {
    private let course: OEXCourse?
    
    lazy var type: CourseAccessErrorType = {
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
