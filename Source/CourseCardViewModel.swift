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
            guard let end = end else {
                return nil
            }
            
            let formattedEndDate = (DateFormatting.format(asMonthDayString: end as NSDate)) ?? ""
            
            // If Old date is older than current date
            if isEndDateOld {
                return Strings.courseEnded(endDate: formattedEndDate)
            }
            else{
                return Strings.courseEnding(endDate: formattedEndDate)
            }
        }
        else {  // Start date is newer than current date
            switch start_display_info.type {
            case .string where start_display_info.displayDate != nil:
                return Strings.starting(startDate: start_display_info.displayDate!)
            case .timestamp where start_display_info.date != nil:
                let formattedStartDate = DateFormatting.format(asMonthDayString: start_display_info.date! as NSDate)
                return Strings.starting(startDate: formattedStartDate ?? "")
            case .none, .timestamp, .string:
                return Strings.starting(startDate: Strings.soon)
            }
        }
    }
    
}
