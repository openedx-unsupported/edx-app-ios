//
//  CourseCardViewModel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class CourseCardViewModel : NSObject {
    
    private let dateText: String
    private let persistImage: Bool
    private let wrapTitle: Bool
    private let course: OEXCourse
    
    private init(course: OEXCourse, dateText: String, persistImage: Bool, wrapTitle: Bool = false) {
        self.dateText = dateText
        self.persistImage = persistImage
        self.course = course
        self.wrapTitle = wrapTitle
    }
    
    var title : String? {
        return course.name
    }
    
    var courseImageURL: String? {
        return course.courseImageURL
    }
    
    static func onHome(course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, dateText: course.nextRelevantDate ?? "", persistImage: true, wrapTitle: true)
    }
    
    static func onDashboard(course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, dateText: course.nextRelevantDate ?? "", persistImage: true, wrapTitle: true)
    }
    
    static func onCourseCatalog(course: OEXCourse, wrapTitle: Bool = false) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, dateText: course.nextRelevantDate ?? "", persistImage: false, wrapTitle: wrapTitle)
    }
    
    static func onCourseOutline(course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, dateText: course.nextRelevantDate ?? "", persistImage: true, wrapTitle: true)
    }
    
    func apply(card : CourseCardView, networkManager: NetworkManager) {
        card.titleText = title
        card.dateText = dateText
        card.course = course
        
        if wrapTitle {
            card.wrapTitleLabel()
        }
        
        let remoteImage : RemoteImage
        let placeholder = UIImage(named: "placeholderCourseCardImage")
        if let relativeImageURL = courseImageURL,
            let imageURL = URL(string: relativeImageURL, relativeTo: networkManager.baseURL)
        {
            remoteImage = RemoteImageImpl(
                url: imageURL.absoluteString,
                networkManager: networkManager,
                placeholder: placeholder,
                persist: persistImage)
        }
        else {
            remoteImage = RemoteImageJustImage(image: placeholder)
        }
        
        card.coverImage = remoteImage
    }
    
}

extension OEXCourse {
    
    var nextRelevantDate : String?  {
        // If start date is older than current date
        if isStartDateOld {

            if let _ = audit_expiry_date {
                return formattedAuditExpiryDate
            }

            guard let end = end else {
                return nil
            }

            let formattedEndDate = (DateFormatting.format(asMonthDayString: end as NSDate)) ?? ""
            
            return isEndDateOld ? Strings.Course.ended(endDate: formattedEndDate) : Strings.Course.ending(endDate: formattedEndDate)
        }
        else {  // Start date is newer than current date
            switch start_display_info.type {
            case .string where start_display_info.displayDate != nil:
                return Strings.Course.starting(startDate: start_display_info.displayDate!)
            case .timestamp where start_display_info.date != nil:
                let formattedStartDate = DateFormatting.format(asMonthDayString: start_display_info.date! as NSDate)
                return Strings.Course.starting(startDate: formattedStartDate ?? "")
            case .none, .timestamp, .string:
                return Strings.Course.starting(startDate: Strings.soon)
            @unknown default:
                return ""
            }
        }
    }

    private var formattedAuditExpiryDate: String {
        guard let auditExpiry = audit_expiry_date as NSDate? else {return "" }

        let formattedExpiryDate = (DateFormatting.format(asMonthDayString: auditExpiry)) ?? ""
        let timeSpan = 30 // number of days
        if isAuditExpired {
            let days = auditExpiry.daysAgo()
            if days < 1 { // showing time for better readability
                return Strings.Course.Audit.expiredAgo(timeDuaration: auditExpiry.displayDate)
            }

            if days <= timeSpan {
                return Strings.Course.Audit.expiredDaysAgo(days: "\(days)")
            }
            else {
                return Strings.Course.Audit.expiredOn(expiryDate: formattedExpiryDate)
            }
        }
        else {
            let days = auditExpiry.daysUntil()
            if days < 1 {
                return Strings.Course.Audit.expiresIn(timeDuration: remainingTime)
            }

            if days <= timeSpan {
                return Strings.Course.Audit.expiresIn(timeDuration: Strings.Course.Audit.days(days: "\(days)"))
            }
            else {
                return Strings.Course.Audit.expiresOn(expiryDate: formattedExpiryDate)
            }
        }
    }

    private var remainingTime: String {
        guard let auditExpiry = audit_expiry_date else { return "" }

        let calendar = NSCalendar.current
        let unitFlags = Set<Calendar.Component>([.second,.minute,.hour])

        let components = calendar.dateComponents(unitFlags, from: Date(), to: auditExpiry)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        let seconds = components.second ?? 0

        if hours >= 1 {
            return Strings.courseAuditRemainingHours(hours: hours)
        }

        if minutes >= 1 {
            return Strings.courseAuditRemainingMinutes(minutes: minutes)
        }

        if seconds >= 1 {
            return Strings.courseAuditRemainingSeconds(seconds: seconds)
        }

        return ""
    }
}
