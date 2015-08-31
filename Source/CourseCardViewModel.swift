//
//  CourseCardViewModel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

@objc class CourseCardViewModel : NSObject {

    class func applyCourse(course: OEXCourse, to infoView: CourseDashboardCourseInfoView) {
        infoView.course = course
        infoView.titleText = course.name
        infoView.detailText = course.org! +  " | "  + course.number! // Show course ced
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
        
        infoView.bannerText = bannerText
        infoView.setCoverImage()
    }

}