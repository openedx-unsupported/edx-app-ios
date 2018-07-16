//
//  OEXRouter+WebView.swift
//  edX
//
//  Created by Zeeshan Arif on 7/14/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

let myProgramDetailURL = "https://courses.edx.org/dashboard/{path_id}?mobile_only=true"
extension OEXRouter {
    
    private func appURLHostIfValid(url: URL) -> AppURLHost? {
        guard url.isValidAppURLScheme, let appURLHost = AppURLHost(rawValue: url.appURLHost) else {
            return nil
        }
        return appURLHost
    }
    @objc
    func navigate(to url: URL, from controller: UIViewController, bottomBar: UIView?) -> Bool {
        guard let appURLHost = appURLHostIfValid(url: url) else { return false }
        switch appURLHost {
        case .courseDetail:
            // TODO: Discussion Required related to /course/{path_id}
            if let courseDetailPath = getCourseDetailPath(from: url),
                let courseDetailURLString = environment.config.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate?.replacingOccurrences(of: AppURLString.pathPlaceHolder.rawValue, with: courseDetailPath),
                let courseDetailURL = URL(string: courseDetailURLString) {
                showCourseDetails(from: controller, with: courseDetailURL, bottomBar: bottomBar)
            }
            break
        case .courseEnrollment:
            if let urlData = parse(url: url), let courseId = urlData.courseId {
                enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn, from: controller)
            }
            break
        case .enrolledCourseDetail:
            if let urlData = parse(url: url), let courseId = urlData.courseId {
                let environment = OEXRouter.shared().environment
                environment.router?.showCourseWithID(courseID: courseId, fromController: controller, animated: true)
            }
            break
        case .enrolledProgramDetail:
            if let programDetailsURL = getEnrolledProgramDetailsURL(from: url) {
                showEnrolledProgramDetails(with: programDetailsURL, from: controller)
            }
            break
        }
        return true
    }
    
    private func showCourseDetails(from controller: UIViewController, with url: URL, bottomBar: UIView?) {
        let courseInfoViewController = OEXCourseInfoViewController(environment: environment, courseInfoURL: url, bottomBar: bottomBar?.copy() as? UIView)
        controller.navigationController?.pushViewController(courseInfoViewController, animated: true)
    }
    
    private func getCourseDetailPath(from url: URL) -> String? {
        return url.isValidAppURLScheme && url.appURLHost == AppURLHost.courseDetail.rawValue ? url.queryParameters?[AppURLParameterKey.pathId] as? String : nil
    }
    
    private func parse(url: URL) -> (courseId: String?, emailOptIn: Bool)? {
        guard url.isValidAppURLScheme, (url.appURLHost == AppURLHost.courseEnrollment.rawValue || url.appURLHost == AppURLHost.enrolledCourseDetail
            .rawValue) else {
            return nil
        }
        let courseId = url.queryParameters?[AppURLParameterKey.courseId] as? String
        let emailOptIn = url.queryParameters?[AppURLParameterKey.emailOptIn] as? Bool
        return (courseId , emailOptIn ?? false)
    }
    
    private func showMainScreen(with message: String, and courseId: String, from controller: UIViewController) {
        OEXRouter.shared().showMyCourses(animated: true, pushingCourseWithID: courseId)
        perform(#selector(postEnrollmentSuccessNotification), with: message, afterDelay: 0.5)
    }
    
    @objc private func postEnrollmentSuccessNotification(message: String, from controller: UIViewController) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: EnrollmentShared.successNotification), object: message)
        if controller.isModal() {
            controller.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func enrollInCourse(courseID: String, emailOpt: Bool, from controller: UIViewController) {
        
        let environment = OEXRouter.shared().environment;
        environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentClicked.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseClicked.rawValue)
        
        guard let _ = OEXSession.shared()?.currentUser else {
            showSignUpScreen(from: controller, completion: {
                self.enrollInCourse(courseID: courseID, emailOpt: emailOpt, from: controller)
            })
            return;
        }
        
        if let _ = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID) {
            showMainScreen(with: Strings.findCoursesAlreadyEnrolledMessage, and: courseID, from: controller)
            return
        }
        
        let request = CourseCatalogAPI.enroll(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentSuccess.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseSuccess.rawValue)
                self?.showMainScreen(with: Strings.findCoursesEnrollmentSuccessfulMessage, and: courseID, from: controller)
            }
            else {
                controller.showOverlay(withMessage: Strings.findCoursesEnrollmentErrorDescription)
            }
        }
    }
    
    private func getEnrolledProgramDetailsURL(from url: URL) -> URL? {
        guard url.isValidAppURLScheme,
            let path = url.queryParameters?[AppURLParameterKey.pathId] as? String else {
                return nil
        }
        let programDetailUrlString = myProgramDetailURL.replacingOccurrences(of: AppURLString.pathPlaceHolder.rawValue, with: path)
        return URL(string: programDetailUrlString)
    }
    
    private func showEnrolledProgramDetails(with url: URL, from controller: UIViewController) {
        let programDetailsController = MyProgramsWebViewController(environment: environment, programDetailsURL: url) //ProgramDetailsWebViewController(with: url, webViewType: .enrolled)
        controller.navigationController?.pushViewController(programDetailsController, animated: true)
    }
}
