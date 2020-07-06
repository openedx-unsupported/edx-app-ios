//
//  CourseDates.swift
//  edX
//
//  Created by Muhammad Umer on 01/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation


public class CourseDateModel: NSObject {
    var courseDateBlocks: [CourseDateBlock] = []
    let datesBannerInfo: DatesBannerInfo?
    let learnerIsFullAccess: Bool
    let missedDeadlines: Bool
    let missedGatedContent: Bool
    let userTimezone : String
    let verifiedUpgradeLink: String
    
    public init?(json: JSON) {
        let courseDateBlocksArray = json["course_date_blocks"].array ?? []
        for courseDateBlocksJsonObject in courseDateBlocksArray {
            if let courseDateblock = CourseDateBlock(json: courseDateBlocksJsonObject) {
                courseDateBlocks.append(courseDateblock)
            }
        }
        let datesBannerInfoJson = json["dates_banner_info"]
        datesBannerInfo = DatesBannerInfo(json: datesBannerInfoJson) ?? nil
        learnerIsFullAccess = json["learner_is_full_access"].bool ?? false
        missedDeadlines = json["missed_deadlines"].bool ?? false
        missedGatedContent = json["missed_gated_content"].bool ?? false
        userTimezone = json["user_timezone"].string ?? ""
        verifiedUpgradeLink = json["verified_upgrade_link"].string ?? ""
    }
}

class DatesBannerInfo: NSObject {
    let contentTypeGatingEnabled: Bool
    let missedDeadlines: Bool
    let missedGatedContent: Bool
    let verifiedUpgradeLink: String
    
    public init?(json: JSON) {
        contentTypeGatingEnabled = json["content_type_gating_enabled"].bool ?? false
        missedDeadlines = json["missed_deadlines"].bool ?? false
        missedGatedContent = json["missed_gated_content"].bool ?? false
        verifiedUpgradeLink = json["verified_upgrade_link"].string ?? ""
    }
}

class CourseDateBlock: NSObject{
    let date: String
    let dateType: String
    let descriptionField: String
    let learnerHasAccess: Bool
    let link: String
    let linkText: String
    let title: String
    
    public init?(json: JSON) {
        date = json["date"].string ?? ""
        dateType = json["date_type"].string ?? ""
        descriptionField = json["description"].string ?? ""
        learnerHasAccess = json["learner_has_access"].bool ?? false
        link = json["link"].string ?? ""
        linkText = json["link_text"].string ?? ""
        title = json["title"].string ?? ""
    }
}
