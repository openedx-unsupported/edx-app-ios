
//
//  DiscoveryHelper.swift
//  edX
//
//  Created by Salman on 17/07/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

enum URIString: String {
    case appURLScheme = "edxapp"
    case pathPlaceHolder = "{path_id}"
}

fileprivate enum URLParameterKeys: String, RawStringExtractable {
    case pathId = "path_id";
    case courseId = "course_id"
    case emailOptIn = "email_opt_in"
}

// Define Your Hosts Here
enum WebviewActions: String {
    case courseEnrollment = "enroll"
    case courseDetail = "course_info"
    case enrolledCourseDetail = "enrolled_course_info"
    case enrolledProgramDetail = "enrolled_program_info"
    case programDetail = "program_info"
    case courseProgram = "course"
}

@objc class DiscoveryHelper: NSObject {

    typealias Environment = OEXRouterProvider & OEXConfigProvider

     class func urlAction(from url: URL) -> WebviewActions? {
        guard url.isValidAppURLScheme, let url = WebviewActions(rawValue: url.appURLHost) else {
            return nil
        }
        return url
    }
    
    @objc class func detailPathID(from url: URL) -> String? {
        guard url.isValidAppURLScheme, url.appURLHost == WebviewActions.courseDetail.rawValue, let path = url.queryParameters?[URLParameterKeys.pathId] as? String else {
            return nil
        }
        
        return path
    }
    
    class func parse(url: URL) -> (courseId: String?, emailOptIn: Bool)? {
        guard url.isValidAppURLScheme else {
                return nil
        }
        let courseId = url.queryParameters?[URLParameterKeys.courseId] as? String
        let emailOptIn = (url.queryParameters?[URLParameterKeys.emailOptIn] as? String).flatMap {Bool($0)}
    
        return (courseId , emailOptIn ?? false)
    }
    
    private class func showCourseEnrollmentFailureAlert(controller: UIViewController) {
        UIAlertController().showAlert(withTitle: Strings.findCoursesEnrollmentErrorTitle, message: Strings.findCoursesUnableToEnrollErrorDescription(platformName: OEXConfig.shared().platformName()), cancelButtonTitle: Strings.ok, onViewController: controller)
    }
    
    class func programDetailURL(from url: URL, config: OEXConfig) -> URL? {
        guard url.isValidAppURLScheme, let path = url.queryParameters?[URLParameterKeys.pathId] as? String,  let myProgramDetailURL = config.programConfig.programDetailURLTemplate else {
                return nil
        }
        let programDetailUrlString = myProgramDetailURL.replacingOccurrences(of: URIString.pathPlaceHolder.rawValue, with: path)
        return URL(string: programDetailUrlString)
    }
    
    private class func showMainScreen(with message: String, and courseId: String, from controller: UIViewController) {
        OEXRouter.shared().showMyCourses(animated: true, pushingCourseWithID: courseId)
        let delay = DispatchTime.now() + Double(Int64(0.5 * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay) {
           postEnrollmentSuccessNotification(message: message, from: controller)
        }
    }
    
    private class func postEnrollmentSuccessNotification(message: String, from controller: UIViewController) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: EnrollmentShared.successNotification), object: message)
        if controller.isModal() || controller.isRootModal() {
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
            return
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
    
    class func programDetailPathId(from url: URL) -> String? {
        guard url.isValidAppURLScheme,
            url.appURLHost == WebviewActions.programDetail.rawValue,
            let path = url.queryParameters?[URLParameterKeys.pathId] as? String else {
            return nil
        }
        return path
    }
    
}

extension DiscoveryHelper {
    private class func enrollInCourse(with url: URL, from controller: UIViewController) {
        if let urlData = parse(url: url), let courseId = urlData.courseId {
            enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn, from: controller)
        }
    }
    
    @objc class func navigate(to url: URL, from controller: UIViewController, bottomBar: UIView?, environment: Environment) -> Bool {
        guard let urlAction = urlAction(from: url) else { return false }
        switch urlAction {
        case .courseEnrollment:
            enrollInCourse(with: url, from: controller)
            break
        case .courseDetail:
            guard let courseDetailPath = detailPathID(from: url) else { return false }
            environment.router?.showCourseDetails(from: controller, with: courseDetailPath, bottomBar: bottomBar)
            break
        case .enrolledCourseDetail:
            guard let urlData = parse(url: url), let courseId = urlData.courseId else { return false }
            environment.router?.showCourseWithID(courseID: courseId, fromController: controller, animated: true)
            break
        case .enrolledProgramDetail:
            guard let programDetailsURL = programDetailURL(from: url, config: environment.config) else { return false }
            environment.router?.showProgramDetails(with: programDetailsURL, from: controller)
            break
        case .programDetail:
            guard let pathId = programDetailPathId(from: url) else { return false }
            environment.router?.showProgramDetail(from: controller, with: pathId, bottomBar: bottomBar)
            break
        case .courseProgram:
            environment.router?.showDiscoveryController(from: controller, type: .discovery, isUserLoggedIn: true, pathID: nil)
            break
        }
        
        return true
    }
}

