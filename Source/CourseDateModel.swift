//
//  CourseDates.swift
//  edX
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

enum BlockStatusType {
    case completed
    case today
    case pastDue
    case dueNext
    case unreleased
    case verifiedOnly
    case assignment
    case verifiedUpgradeDeadline
    case courseExpiredDate
    case verificationDeadlineDate
    case certificateAvailbleDate
    case courseStartDate
    case courseEndDate
    case event
    
    var localized: String {
        switch self {
        case .completed:
            return Strings.Coursedates.completed
            
        case .today:
            return Strings.Coursedates.today
            
        case .pastDue:
            return Strings.Coursedates.pastDue
            
        case .dueNext:
            return Strings.Coursedates.dueNext
            
        case .unreleased:
            return Strings.Coursedates.unreleased
            
        case .verifiedOnly:
            return Strings.Coursedates.verfiedOnly
            
        case .event:
            return Strings.Coursedates.event
            
        case .assignment:
            return Strings.Coursedates.assignmentDueDate
            
        case .verifiedUpgradeDeadline:
            return Strings.Coursedates.verifiedUpgradeDeadline
            
        case .courseExpiredDate:
            return Strings.Coursedates.courseExpiredDate
            
        case .verificationDeadlineDate:
            return Strings.Coursedates.verificationDeadlineDate
            
        case .certificateAvailbleDate:
            return Strings.Coursedates.certificateAvailableDate
            
        case .courseStartDate:
            return Strings.Coursedates.courseStartDate
            
        case .courseEndDate:
            return Strings.Coursedates.courseEndDate
        }
    }
    
    static func typeOf(dateType: String) -> BlockStatusType {
        switch dateType {
        case "assignment-due-date":
            return .assignment
            
        case "verified-upgrade-deadline":
            return .verifiedUpgradeDeadline
            
        case "course-expired-date":
            return .courseExpiredDate
            
        case "verification-deadline-date":
            return .verificationDeadlineDate
            
        case "certificate-available-date":
            return .certificateAvailbleDate
            
        case "course-start-date":
            return .courseStartDate
            
        case "course-end-date":
            return .courseEndDate
            
        default:
            return .event
        }
    }
}

class CourseDateModel {
    private enum Keys: String, RawStringExtractable {
        case courseDateBlocks = "course_date_blocks"
        case datesBannerInfo = "dates_banner_info"
        case learnerIsFullAccess = "learner_is_full_access"
        case missedDeadlines = "missed_deadlines"
        case missedGatedContent = "missed_gated_content"
        case userTimezone = "user_timezone"
        case verifiedUpgradeLink = "verified_upgrade_link"
    }
    
    var courseDateBlocks: [CourseDateBlock] = []
    var datesBannerInfo: DatesBannerInfo? = nil
    var learnerIsFullAccess: Bool = false
    var missedDeadlines: Bool = false
    var missedGatedContent: Bool = false
    var userTimezone: String = ""
    var verifiedUpgradeLink: String = ""
    
    public init?(json: JSON) {
        let courseDateBlocksArray = json[Keys.courseDateBlocks].array ?? []
        courseDateBlocks = courseDateBlocksArray.compactMap { CourseDateBlock(json: $0) }
        let datesBannerInfoJson = json[Keys.datesBannerInfo]
        datesBannerInfo = DatesBannerInfo(json: datesBannerInfoJson) ?? nil
        learnerIsFullAccess = json[Keys.learnerIsFullAccess].bool ?? false
        missedDeadlines = json[Keys.missedDeadlines].bool ?? false
        missedGatedContent = json[Keys.missedGatedContent].bool ?? false
        userTimezone = json[Keys.userTimezone].string ?? ""
        verifiedUpgradeLink = json[Keys.verifiedUpgradeLink].string ?? ""
    }
}

class DatesBannerInfo {
    private enum Keys: String, RawStringExtractable {
        case contentTypeGatingEnabled = "content_type_gating_enabled"
        case missedDeadlines = "missed_deadlines"
        case missedGatedContent = "missed_gated_content"
        case verifiedUpgradeLink = "verified_upgrade_link"
    }
    
    let contentTypeGatingEnabled: Bool
    let missedDeadlines: Bool
    let missedGatedContent: Bool
    let verifiedUpgradeLink: String
    
    public init?(json: JSON) {
        contentTypeGatingEnabled = json[Keys.contentTypeGatingEnabled].bool ?? false
        missedDeadlines = json[Keys.missedDeadlines].bool ?? false
        missedGatedContent = json[Keys.missedGatedContent].bool ?? false
        verifiedUpgradeLink = json[Keys.verifiedUpgradeLink].string ?? ""
    }
}

class CourseDateBlock {
    private enum Keys: String, RawStringExtractable {
        case complete = "complete"
        case date = "date"
        case dateType = "date_type"
        case description = "description"
        case learnerHasAccess = "learner_has_access"
        case link = "link"
        case linkText = "link_text"
        case title = "title"
        case extraInfo = "extra_info"
    }
    
    var complete: Bool = false
    var blockDate: Date = Date().stripTimeStamp()
    var dateType: String = ""
    var description: String = ""
    var learnerHasAccess: Bool = false
    var link: String = ""
    var linkText: String = ""
    var title: String = ""
    var dateText: String = ""
    var today = Date().stripTimeStamp()
    var extraInfo: String = ""
    
    public init?(json: JSON) {
        complete = json[Keys.complete].bool ?? false
        let date = json[Keys.date].string ?? ""
        dateType = json[Keys.dateType].string ?? ""
        description = json[Keys.description].string ?? ""
        learnerHasAccess = json[Keys.learnerHasAccess].bool ?? false
        link = json[Keys.link].string ?? ""
        linkText = json[Keys.linkText].string ?? ""
        title = json[Keys.title].string ?? ""
        extraInfo = json[Keys.extraInfo].string ?? ""
        
        guard let formattedDate = DateFormatting.date(withServerString: date) else {
            let today = NSDate()
            blockDate = (today as Date).stripTimeStamp()
            dateText = DateFormatting.format(asWeekDayMonthDateYear: today as Date)
            return
        }
        blockDate = (formattedDate as Date).stripTimeStamp()
        dateText = DateFormatting.format(asWeekDayMonthDateYear: blockDate as Date)
    }
    
    init(date: Date = Date()) {
        let today = date.stripTimeStamp() as NSDate
        blockDate = (today as Date).stripTimeStamp()
        dateText = DateFormatting.format(asWeekDayMonthDateYear: today as Date)
    }
}

extension CourseDateBlock {
    var isInPast: Bool {
        return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedAscending
    }
    
    var isInToday: Bool {
        if dateType.isEmpty {
            return true
        } else {
            return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedSame
        }
    }
    
    var isInFuture: Bool {
        return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedDescending
    }
    
    var blockStatus: BlockStatusType {
        return calculateBlockStatus(type: dateType)
    }
    
    var isAssignment: Bool {
        return BlockStatusType.typeOf(dateType: dateType) == .assignment
    }
    
    var isVerifiedOnly: Bool {
        return !learnerHasAccess
    }
    
    var isComlete: Bool {
        return complete
    }
    
    var isLearnerAssignment: Bool {
        return learnerHasAccess && isAssignment
    }

    var isPastDue: Bool {
        return !complete && (blockDate < today)
    }

    var isUnreleased: Bool {
        return link.isEmpty
    }
    
    var showLink: Bool {
        return !isUnreleased && isLearnerAssignment
    }
    
    var available: Bool {
        return learnerHasAccess && (!isUnreleased || !isLearnerAssignment)
    }
    
    var hasDesription: Bool {
        return !description.isEmpty
    }
    
    /*
     For completeness sake, here are the badge triggers:
     completed: should be if the item has the completed boolean to true (and is an assignment)
     past due: is an assignment, the learner has access, is not complete, and due in the past
     due next: is an assignment, the learner has access, is not complete, and is the next assignment due
     unreleased: is an assignment, the learner has access, and there's no link property (and/or it's empty, I forget which)
     verified only: the learner does not have access (note that it can be an assignment or something else)
     verification-deadline-date:
     certificate-available-date:
     course-start-date:
     course-end-date:
     */
    
    private func calculateBlockStatus(type: String) -> BlockStatusType {
        if isInToday {
            return .today
        }
        
        if complete {
            return .completed
        } else {
            if !learnerHasAccess {
                return .verifiedOnly
            } else if learnerHasAccess && isAssignment {
                if isInPast {
                    return isUnreleased ? .unreleased : .pastDue
                } else if isInToday {
                    return .today
                } else if isInFuture {
                    return isUnreleased ? .unreleased : .dueNext
                }
            } else if learnerHasAccess && !isAssignment {
                return BlockStatusType.typeOf(dateType: type)
            }
            
            return .event
        }
    }
}
