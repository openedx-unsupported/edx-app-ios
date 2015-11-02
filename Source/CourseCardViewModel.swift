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
    class func applyCourse(course: OEXCourse, toCardView cardView: CourseCardView, forType cardType : CardType = .Home, videoDetails : String? = nil) {
        cardView.course = course
        cardView.titleText = course.name
        cardView.detailText = course.courseRunForCardType(cardType)
        
        switch cardType {
        case .Home:
            cardView.bottomTrailingText = course.nextRelevantDateUpperCaseString
        case .Video:
            cardView.bottomTrailingText = videoDetails
        case .Dashboard:
            cardView.bottomTrailingText = nil
        }
        cardView.setCoverImage()
        
    }

}

extension OEXCourse {
    func courseRunForCardType(cardType : CardType) -> String {
        switch cardType {
        case .Home, .Video:
            return String.joinInNaturalLayout([self.org, self.number], separator : " | ")
        case .Dashboard:
            return String.joinInNaturalLayout([self.org, self.number, self.nextRelevantDateUpperCaseString], separator : " | ")
        }
    }
    
    var nextRelevantDate : String?  {
        // If start date is older than current date
        if self.isStartDateOld && self.end != nil {
            let formattedEndDate = OEXDateFormatting.formatAsMonthDayString(self.end)
            
            // If Old date is older than current date
            if self.isEndDateOld {
                return Strings.courseEnded(endDate: formattedEndDate)
            } else {
                return Strings.courseEnding(endDate: formattedEndDate)            }
        } else {  // Start date is newer than current date
            let error_code = self.courseware_access!.error_code
            let startDateNil: Bool = self.start_display_info.date == nil
            let displayInfoTime: Bool = error_code != OEXAccessError.StartDateError || self.start_display_info.type == OEXStartType.Timestamp
            if !self.isStartDateOld && !startDateNil && displayInfoTime {
                let formattedStartDate = OEXDateFormatting.formatAsMonthDayString(self.start_display_info.date)
                return Strings.starting(startDate: formattedStartDate)
            }
        }
    return nil
    }
    
    private var nextRelevantDateUpperCaseString : String? {
        return nextRelevantDate?.uppercaseString
    }
}