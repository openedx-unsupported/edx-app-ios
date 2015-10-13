//
//  CourseCardViewModel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

@objc enum CardType : Int {
    case Home
    case Video
    case Dashboard
}

@objc class CourseCardViewModel : NSObject {
    
    //Using Video details as a param because we can't use associated enum values from objc
    class func applyCourse(course: OEXCourse, to infoView: CourseDashboardCourseInfoView, forType cardType : CardType = .Home, videoDetails : String? = nil) {
        infoView.course = course
        infoView.titleText = course.name
        infoView.detailText =  String.joinInNaturalLayout([course.org ?? "", " | ", course.number ?? ""])
        var bannerText: String? = nil
        
        
        // If start date is older than current date
        if course.isStartDateOld && course.end != nil {
            let formattedEndDate = OEXDateFormatting.formatAsMonthDayString(course.end)
            
            // If Old date is older than current date
            if course.isEndDateOld {
                bannerText = OEXLocalizedString("ENDED", nil) + " - " + formattedEndDate
            } else {
                bannerText = OEXLocalizedString("ENDING", nil).oex_uppercaseStringInCurrentLocale() + " - " + formattedEndDate
            }
        } else {  // Start date is newer than current date
            let error_code = course.courseware_access!.error_code
            let startDateNil: Bool = course.start_display_info.date == nil
            let displayInfoTime: Bool = error_code != OEXAccessError.StartDateError || course.start_display_info.type == OEXStartType.Timestamp
            if !course.isStartDateOld && !startDateNil && displayInfoTime {
                let formattedStartDate = OEXDateFormatting.formatAsMonthDayString(course.start_display_info.date)
                bannerText = OEXLocalizedString("STARTING", nil).oex_uppercaseStringInCurrentLocale() + " - " + formattedStartDate
            }
        }
        
        switch cardType {
        case .Home:
            infoView.bannerText = bannerText
        case .Video:
            infoView.bottomTrailingText = videoDetails
        case .Dashboard:
            infoView.bannerText = nil
        }
        infoView.setCoverImage()
        
    }

}