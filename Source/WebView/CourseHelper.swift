//
//  CourseHelper.swift
//  edX
//
//  Created by Salman on 17/07/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

enum AppURLString: String {
    case appURLScheme = "edxapp"
    case pathPlaceHolder = "{path_id}"
    case coursePathPrefix = "course/"
}

enum AppURLParameterKey: String, RawStringExtractable {
    case pathId = "path_id";
    case courseId = "course_id"
    case emailOptIn = "email_opt_in"
}

// Define Your Hosts Here
enum AppURLHost: String {
    case courseEnrollment = "enroll"
    case courseDetail = "course_info"
    case enrolledCourseDetail = "enrolled_course_info"
    case enrolledProgramDetail = "enrolled_program_info"
}

class CourseHelper: NSObject {

     class func appURLHostIfValid(url: URL) -> AppURLHost? {
        guard url.isValidAppURLScheme, let appURLHost = AppURLHost(rawValue: url.appURLHost) else {
            return nil
        }
        return appURLHost
    }
    
    class func getCourseDetailPath(from url: URL) -> String? {
        guard url.isValidAppURLScheme, url.appURLHost == AppURLHost.courseDetail.rawValue, let path = url.queryParameters?[AppURLParameterKey.pathId] as? String else {
            return nil
        }
        
        // the site sends us things of the form "course/<path_id>" we only want the path id
        return path.replacingOccurrences(of: AppURLString.coursePathPrefix.rawValue, with: "")
    }
    
    class func parse(url: URL) -> (courseId: String?, emailOptIn: Bool)? {
        guard url.isValidAppURLScheme, (url.appURLHost == AppURLHost.courseEnrollment.rawValue || url.appURLHost == AppURLHost.enrolledCourseDetail
            .rawValue) else {
                return nil
        }
        let courseId = url.queryParameters?[AppURLParameterKey.courseId] as? String
        let emailOptIn = url.queryParameters?[AppURLParameterKey.emailOptIn] as? Bool
        return (courseId , emailOptIn ?? false)
    }
    
    class func showCourseEnrollmentFailureAlert(controller: UIViewController) {
        UIAlertController().showAlert(withTitle: Strings.findCoursesEnrollmentErrorTitle, message: Strings.findCoursesUnableToEnrollErrorDescription(platformName: OEXConfig.shared().platformName()), cancelButtonTitle: Strings.ok, onViewController: controller)
    }
    
    class func getEnrolledProgramDetailsURL(from url: URL) -> URL? {
        guard url.isValidAppURLScheme,
            let path = url.queryParameters?[AppURLParameterKey.pathId] as? String else {
                return nil
        }
        let myProgramDetailURL = "https://courses.edx.org/dashboard/{path_id}?mobile_only=true"
        let programDetailUrlString = myProgramDetailURL.replacingOccurrences(of: AppURLString.pathPlaceHolder.rawValue, with: path)
        return URL(string: programDetailUrlString)
    }
    
    class func showMainScreen(with message: String, and courseId: String, from controller: UIViewController) {
        OEXRouter.shared().showMyCourses(animated: true, pushingCourseWithID: courseId)
        let delay = DispatchTime.now() + Double(Int64(0.5 * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay) {
           postEnrollmentSuccessNotification(message: message, from: controller)
        }
    }
    
    class func postEnrollmentSuccessNotification(message: String, from controller: UIViewController) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: EnrollmentShared.successNotification), object: message)
        if controller.isModal() {
            controller.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc class func enrollInCourse(courseID: String, emailOpt: Bool, from controller: UIViewController) {
        
        let environment = OEXRouter.shared().environment;
        environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentClicked.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseClicked.rawValue)
        
        guard let _ = OEXSession.shared()?.currentUser else {
            OEXRouter.shared().showSignUpScreen(from: controller, completion: {
                self.enrollInCourse(courseID: courseID, emailOpt: emailOpt, from: controller)
            })
            return;
        }
        
        if let _ = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID) {
            showMainScreen(with: Strings.findCoursesAlreadyEnrolledMessage, and: courseID, from: controller)
            return
        }
        
        let request = CourseCatalogAPI.enroll(courseID: courseID)
        environment.networkManager.taskForRequest(request) { response in
            if response.response?.httpStatusCode.is2xx ?? false {
                environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentSuccess.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseSuccess.rawValue)
                showMainScreen(with: Strings.findCoursesEnrollmentSuccessfulMessage, and: courseID, from: controller)
            }
            else if response.response?.httpStatusCode.is4xx ?? false {
                showCourseEnrollmentFailureAlert(controller: controller)
            }
            else {
                controller.showOverlay(withMessage: Strings.findCoursesEnrollmentErrorDescription)
            }
        }
    }
}
