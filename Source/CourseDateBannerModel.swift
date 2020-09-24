//
//  CourseDateBannerModel.swift
//  edX
//
//  Created by Muhammad Umer on 08/09/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

let NOTIFICATION_SHIFT_COURSE_DATES_SUCCESS_FROM_COURSE_DASHBOARD = "ShifCourseDatesSuccessFromCourseDashboard"

struct CourseDateBannerModel {
    private enum Keys: String, RawStringExtractable {
        case bannerInfo = "dates_banner_info"
        case hasEnded = "has_ended"
    }
    
    let bannerInfo: DatesBannerInfo
    let hasEnded: Bool
    
    init(json: JSON) {
        let datesBannerInfoJson = json[Keys.bannerInfo]
        bannerInfo = DatesBannerInfo(json: datesBannerInfoJson)
        hasEnded = json[Keys.hasEnded].boolValue
    }
}

