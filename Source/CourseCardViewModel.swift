//
//  CourseCardViewModel.swift
//  edX
//
//  Created by Michael Katz on 8/31/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

class CourseCardViewModel : NSObject {
    private let detailText: String
    private let bottomTrailingText: String?
    private let persistImage: Bool
    private let wrapTitle: Bool
    private let course: OEXCourse
    
    private init(course: OEXCourse, detailText: String, bottomTrailingText: String?, persistImage: Bool, wrapTitle: Bool = false) {
        self.detailText = detailText
        self.bottomTrailingText = bottomTrailingText
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
    
    static func onMyVideos(course: OEXCourse, collectionInfo: String) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: collectionInfo, persistImage: true)
    }
    
    static func onHome(course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: course.nextRelevantDateUpperCaseString, persistImage: true)
    }
    
    static func onDashboard(course: OEXCourse) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRunIncludingNextDate, bottomTrailingText: nil, persistImage: true, wrapTitle: true)
    }
    
    static func onCourseCatalog(course: OEXCourse, wrapTitle: Bool = false) -> CourseCardViewModel {
        return CourseCardViewModel(course: course, detailText: course.courseRun, bottomTrailingText: course.nextRelevantDateUpperCaseString, persistImage: false, wrapTitle: wrapTitle)
    }
    
    func apply(card : CourseCardView, networkManager: NetworkManager) {
        card.titleText = title
        card.detailText = detailText
        card.bottomTrailingText = bottomTrailingText
        card.course = self.course
        
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
    
    var courseRun : String {
        return String.joinInNaturalLayout(nullableStrings: [self.org, self.number], separator : " | ")
    }
    
    var courseRunIncludingNextDate : String {
        return String.joinInNaturalLayout(nullableStrings: [self.org, self.number, self.nextRelevantDateUpperCaseString], separator : " | ")
    }
    
    var nextRelevantDate : String?  {
        // If start date is older than current date
        if self.isStartDateOld {
            guard let end = self.end else {
                return nil
            }
            
            let formattedEndDate = (DateFormatting.format(asMonthDayString: end as NSDate)) ?? ""
            
            // If Old date is older than current date
            if self.isEndDateOld {
                return Strings.courseEnded(endDate: formattedEndDate)
            }
            else{
                return Strings.courseEnding(endDate: formattedEndDate)
            }
        }
        else {  // Start date is newer than current date
            switch self.start_display_info.type {
            case .string where self.start_display_info.displayDate != nil:
                return Strings.starting(startDate: self.start_display_info.displayDate!)
            case .timestamp where self.start_display_info.date != nil:
                let formattedStartDate = DateFormatting.format(asMonthDayString: self.start_display_info.date! as NSDate)
                return Strings.starting(startDate: formattedStartDate ?? "")
            case .none, .timestamp, .string:
                return Strings.starting(startDate: Strings.soon)
            }
        }
    }
    
    fileprivate var nextRelevantDateUpperCaseString : String? {
        return nextRelevantDate?.oex_uppercaseStringInCurrentLocale()
    }
}
