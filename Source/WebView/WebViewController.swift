//
//  WebViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 7/13/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import WebKit

@objc
protocol WebViewDelegate: class {
    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool
    func webViewContainingController() -> UIViewController
}

@objc
class WebViewController: UIViewController {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider
    private let environment: Environment?
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK:- UIViewController Methods -
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK:- Navigation -
    func appURLHostIfValid(url: URL) -> AppURLHost? {
        guard url.isValidAppURLScheme, let appURLHost = AppURLHost(rawValue: url.appURLHost) else {
            return nil
        }
        return appURLHost
    }
    
    fileprivate func navigate(to url: URL) -> Bool {
        guard let appURLHost = appURLHostIfValid(url: url) else { return false }
        switch appURLHost {
        case .courseDetail:
            if let courseDetailPath = getCourseDetailPath(from: url),
                let courseDetailURLString = environment?.config.courseEnrollmentConfig.webviewConfig.courseInfoURLTemplate?.replacingOccurrences(of: AppURLString.pathPlaceHolder.rawValue, with: courseDetailPath),
                let courseDetailURL = URL(string: courseDetailURLString) {
                showCourseDetails(with: courseDetailURL)
            }
            break
        case .courseEnrollment:
            if let urlData = parse(url: url), let courseId = urlData.courseId {
                enrollInCourse(courseID: courseId, emailOpt: urlData.emailOptIn)
            }
            break
        case .enrolledCourseDetail:
            if let urlData = parse(url: url), let courseId = urlData.courseId {
                let environment = OEXRouter.shared().environment
                environment.router?.showCourseWithID(courseID: courseId, fromController: self, animated: true)
            }
            break
        case .enrolledProgramDetail:
            if let programDetailsURL = getEnrolledProgramDetailsURL(from: url) {
                showEnrolledProgramDetails(with: programDetailsURL)
            }
            break
        }
        return true
    }
    
    private func showCourseDetails(with url: URL) {
//        let courseDetailsWebViewController = CourseDetailsWebViewController(with: url, andBottomBar: bottomBar?.copy() as? UIView)
//        navigationController?.pushViewController(courseDetailsWebViewController, animated: true)
    }
    
    func getCourseDetailPath(from url: URL) -> String? {
        return url.isValidAppURLScheme && url.appURLHost == AppURLHost.courseDetail.rawValue ? url.queryParameters?[AppURLParameterKey.pathId] as? String : nil
    }
    
    func parse(url: URL) -> (courseId: String?, emailOptIn: Bool)? {
        guard url.isValidAppURLScheme, url.appURLHost == AppURLHost.courseEnrollment.rawValue else {
            return nil
        }
        let courseId = url.queryParameters?[AppURLParameterKey.courseId] as? String
        let emailOptIn = url.queryParameters?[AppURLParameterKey.emailOptIn] as? Bool
        return (courseId , emailOptIn ?? false)
    }
    
    private func showMainScreen(with message: String, and courseId: String) {
        OEXRouter.shared().showMyCourses(animated: true, pushingCourseWithID: courseId)
        perform(#selector(postEnrollmentSuccessNotification), with: message, afterDelay: 0.5)
    }
    
    @objc private func postEnrollmentSuccessNotification(message: String) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: EnrollmentShared.successNotification), object: message)
        if isModal() {
            view.window?.rootViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func enrollInCourse(courseID: String, emailOpt: Bool) {
        
        let environment = OEXRouter.shared().environment;
        environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentClicked.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseClicked.rawValue)
        
        guard let _ = OEXSession.shared()?.currentUser else {
            OEXRouter.shared().showSignUpScreen(from: self, completion: {
                self.enrollInCourse(courseID: courseID, emailOpt: emailOpt)
            })
            return;
        }
        
        if let _ = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID) {
            showMainScreen(with: Strings.findCoursesAlreadyEnrolledMessage, and: courseID)
            return
        }
        
        let request = CourseCatalogAPI.enroll(courseID: courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentSuccess.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseSuccess.rawValue)
                self?.showMainScreen(with: Strings.findCoursesEnrollmentSuccessfulMessage, and: courseID)
            }
            else {
                self?.showOverlay(withMessage: Strings.findCoursesEnrollmentErrorDescription)
            }
        }
    }
    
    private func getEnrolledProgramDetailsURL(from url: URL) -> URL? {
//        guard url.isValidAppURLScheme,
//            let path = url.queryParameters?[AppURLParameterKey.pathId] as? String,
//            let programDetailUrlString = enrolledDetailTemplate?.replacingOccurrences(of: AppURLString.pathPlaceHolder.rawValue, with: path)
//            else {
//                return nil
//        }
//        return URL(string: programDetailUrlString)
        return nil
    }
    
    private func showEnrolledProgramDetails(with url: URL) {
//        let controller = ProgramDetailsWebViewController(with: url, webViewType: .enrolled)
//        navigationController?.pushViewController(controller, animated: true)
    }
}

//extension WebViewController: WebViewDelegate {
//    func webView(_ webView: WKWebView, shouldLoad request: URLRequest) -> Bool {
//        guard let url = request.url else { return true }
//        let didNavigate = navigate(to: url)
//        return !didNavigate
//    }
//    
//    func webViewContainingController() -> UIViewController {
//        return self
//    }
//    
//}
