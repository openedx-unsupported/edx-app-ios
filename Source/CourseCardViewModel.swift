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
        if self.isStartDateOld {
            guard let end = self.end else {
                return nil
            }
            
            let formattedEndDate = OEXDateFormatting.formatAsMonthDayString(end)
            
            // If Old date is older than current date
            if self.isEndDateOld {
                return Strings.courseEnded(endDate: formattedEndDate)
            }
            else{
                return Strings.courseEnding(endDate: formattedEndDate)
            }
        }
        else {  // Start date is newer than current date
            switch self.start_display_info.type ?? .None {
            case .String where self.start_display_info.displayDate != nil:
                return Strings.starting(startDate: self.start_display_info.displayDate!)
            case .Timestamp where self.start_display_info.date != nil:
                let formattedStartDate = OEXDateFormatting.formatAsMonthDayString(self.start_display_info.date!)
                return Strings.starting(startDate: formattedStartDate)
            case .None, .Timestamp, .String:
                return Strings.starting(startDate: Strings.soon)
            }
        }
    }
    
    private var nextRelevantDateUpperCaseString : String? {
        return nextRelevantDate?.uppercaseString
    }
}