//
//  CourseDates.swift
//  edX
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

enum DateBlockStatus {
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
    
    static func status(of type: String) -> DateBlockStatus {
        switch type {
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

struct CourseDateModel {
    private enum Keys: String, RawStringExtractable {
        case courseDateBlocks = "course_date_blocks"
        case datesBannerInfo = "dates_banner_info"
        case learnerHasFullAccess = "learner_is_full_access"
        case missedDeadline = "missed_deadlines"
        case missedGatedContent = "missed_gated_content"
        case userTimezone = "user_timezone"
        case verifiedUpgradeLink = "verified_upgrade_link"
    }
    
    var dateBlocks: [CourseDateBlock] = []
    var bannerInfo: DatesBannerInfo? = nil
    var learnerHasFullAccess: Bool = false
    var missedDeadline: Bool = false
    var missedGatedContent: Bool = false
    var verifiedUpgradeLink: String = ""
    var userTimezone: String?

    var defaultTimeZone: String?  {
        didSet {
            dateBlocks.modifyForEach { block in
                block.preferenceTimeZone = defaultTimeZone
            }
        }
    }
    
    init(json: JSON) {
        let courseDateBlocksArray = json[Keys.courseDateBlocks].array ?? []
        dateBlocks = courseDateBlocksArray.compactMap { CourseDateBlock(json: $0, timeZone: json[Keys.userTimezone].string) }
        let datesBannerInfoJson = json[Keys.datesBannerInfo]
        bannerInfo = DatesBannerInfo(json: datesBannerInfoJson)
        learnerHasFullAccess = json[Keys.learnerHasFullAccess].bool ?? false
        missedDeadline = json[Keys.missedDeadline].bool ?? false
        missedGatedContent = json[Keys.missedGatedContent].bool ?? false
        userTimezone = json[Keys.userTimezone].string ?? nil
        verifiedUpgradeLink = json[Keys.verifiedUpgradeLink].string ?? ""
    }
}

enum BannerInfoStatus {
    case datesTabInfoBanner
    case upgradeToCompleteGradedBanner
    case upgradeToResetBanner
    case resetDatesBanner
    
    case event
    
    var header: String {
        switch self {
        case .datesTabInfoBanner:
            return Strings.Coursedates.ResetDate.TabInfoBanner.header
            
        case .upgradeToCompleteGradedBanner:
            return Strings.Coursedates.ResetDate.UpgradeToCompleteGradedBanner.header
            
        case .upgradeToResetBanner:
            return Strings.Coursedates.ResetDate.UpgradeToResetBanner.header
            
        case .resetDatesBanner:
            return Strings.Coursedates.ResetDate.ResetDateBanner.header
            
        default:
            return ""
        }
    }
    
    var body: String {
        switch self {
        case .datesTabInfoBanner:
            return Strings.Coursedates.ResetDate.TabInfoBanner.body
                        
        case .upgradeToCompleteGradedBanner:
            return Strings.Coursedates.ResetDate.UpgradeToCompleteGradedBanner.body
            
        case .upgradeToResetBanner:
            return Strings.Coursedates.ResetDate.UpgradeToResetBanner.body
            
        case .resetDatesBanner:
            return Strings.Coursedates.ResetDate.ResetDateBanner.body

        default:
            return ""
        }
    }
    
    var button: String {
        switch self {
        case .datesTabInfoBanner:
            return Strings.Coursedates.ResetDate.TabInfoBanner.button
                        
        case .upgradeToCompleteGradedBanner:
            return Strings.Coursedates.ResetDate.UpgradeToCompleteGradedBanner.button
            
        case .upgradeToResetBanner:
            return Strings.Coursedates.ResetDate.UpgradeToResetBanner.button
            
        case .resetDatesBanner:
            return Strings.Coursedates.ResetDate.ResetDateBanner.button

        default:
            return ""
        }
    }
}

struct DatesBannerInfo {
    private enum Keys: String, RawStringExtractable {
        case contentTypeGatingEnabled = "content_type_gating_enabled"
        case missedDeadline = "missed_deadlines"
        case missedGatedContent = "missed_gated_content"
        case verifiedUpgradeLink = "verified_upgrade_link"
    }
    
    let contentTypeGatingEnabled: Bool
    let missedDeadline: Bool
    let missedGatedContent: Bool
    let verifiedUpgradeLink: String
    
    init(json: JSON) {
        contentTypeGatingEnabled = json[Keys.contentTypeGatingEnabled].bool ?? false
        missedDeadline = json[Keys.missedDeadline].bool ?? false
        missedGatedContent = json[Keys.missedGatedContent].bool ?? false
        verifiedUpgradeLink = json[Keys.verifiedUpgradeLink].string ?? ""
    }
    
    var status: BannerInfoStatus {
        if upgradeToCompleteGraded {
            return .upgradeToCompleteGradedBanner
        } else if upgradeToReset {
            return .upgradeToResetBanner
        } else if resetDates {
            return .resetDatesBanner
        } else if showDatesTabBannerInfo {
            return .datesTabInfoBanner
        }
        
        return .event
    }
    
    var showDatesTabBannerInfo: Bool {
        return !missedDeadline
    }
    
    var upgradeToCompleteGraded: Bool {
        return contentTypeGatingEnabled && !missedDeadline
    }
    
    var upgradeToReset: Bool {
        return !upgradeToCompleteGraded && missedDeadline && missedGatedContent
    }
    
    var resetDates: Bool {
        return !upgradeToCompleteGraded && missedDeadline && !missedGatedContent
    }
}

struct CourseDateBlock {
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
    var dateType: String = ""
    var description: String = ""
    var learnerHasAccess: Bool = false
    var link: String = ""
    var linkText: String = ""
    var title: String = ""
    var extraInfo: String = ""
    var dateString: String = ""
    var userTimeZone: String?
    var preferenceTimeZone: String?
    
    var today: Date {
        return Date().stripTimeStamp(timeZone: timeZone)
    }
    
    var blockDate: Date {
        return dateString.isEmpty ? today : getBlockDate(date: dateString)
    }
        
    init(json: JSON, timeZone: String?) {
        complete = json[Keys.complete].bool ?? false
        dateString = json[Keys.date].string ?? ""
        dateType = json[Keys.dateType].string ?? ""
        description = json[Keys.description].string ?? ""
        learnerHasAccess = json[Keys.learnerHasAccess].bool ?? false
        link = json[Keys.link].string ?? ""
        linkText = json[Keys.linkText].string ?? ""
        title = json[Keys.title].string ?? ""
        extraInfo = json[Keys.extraInfo].string ?? ""
        userTimeZone = timeZone
    }
    
    init() {
        dateString = ""
    }
    
    private func getBlockDate(date: String) -> Date {
        guard let formattedDate = DateFormatting.date(withServerString: date, timeZone: timeZone) else {
            return today
        }
        return (formattedDate as Date).stripTimeStamp(timeZone: timeZone)
    }
    
    private var timeZone: TimeZone {
        var timeZone: TimeZone
        
        if let identifier = userTimeZone, let newTimeZone = TimeZone(identifier: identifier) {
            timeZone = newTimeZone
        } else if let abbreviation = preferenceTimeZone, let newTimeZone = TimeZone(abbreviation: abbreviation)  {
            timeZone = newTimeZone
        } else {
            timeZone = TimeZone(abbreviation: "UTC") ?? TimeZone.current
        }
        
        return timeZone
    }
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
extension CourseDateBlock {
    var isInPast: Bool {
        return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedAscending
    }
    
    var isToday: Bool {
        if dateType.isEmpty {
            return true
        } else {
            return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedSame
        }
    }
    
    var isInFuture: Bool {
        return DateFormatting.compareTwoDates(fromDate: blockDate, toDate: today) == .orderedDescending
    }
    
    var blockStatus: DateBlockStatus {
        return getBlockStatus(of: dateType)
    }
    
    var isAssignment: Bool {
        return DateBlockStatus.status(of: dateType) == .assignment
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
    
    var canShowLink: Bool {
        return !isUnreleased && isLearnerAssignment
    }
    
    var isAvailable: Bool {
        return learnerHasAccess && (!isUnreleased || !isLearnerAssignment)
    }
    
    var hasDescription: Bool {
        return !description.isEmpty
    }
    
    private func getBlockStatus(of type: String) -> DateBlockStatus {
        if isToday {
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
                } else if isToday {
                    return .today
                } else if isInFuture {
                    return isUnreleased ? .unreleased : .dueNext
                }
            } else if learnerHasAccess && !isAssignment {
                return DateBlockStatus.status(of: type)
            }
            
            return .event
        }
    }
}

fileprivate extension Date {
    func stripTimeStamp(timeZone: TimeZone) -> Date {
        var calender: Calendar
        
        if inTestingMode {
            calender = Calendar(identifier: .gregorian)
        } else {
            calender = Calendar.current
        }
        
        calender.timeZone = timeZone
        let components = calender.dateComponents([.year, .month, .day], from: self)
        
        return calender.date(from: components) ?? self
    }
}

fileprivate extension Array {
    mutating func modifyForEach(_ body: (_ element: inout Element) -> ()) {
        for index in indices {
            modifyElement(atIndex: index) { body(&$0) }
        }
    }

    mutating func modifyElement(atIndex index: Index, _ modifyElement: (_ element: inout Element) -> ()) {
        var element = self[index]
        modifyElement(&element)
        self[index] = element
    }
}

fileprivate var inTestingMode: Bool {
    return ProcessInfo.processInfo.arguments.contains(where: { $0 == "-UNIT_TEST"})
}
