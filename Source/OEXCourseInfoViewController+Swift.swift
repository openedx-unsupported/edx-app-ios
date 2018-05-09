//
//  OEXCourseInfoViewController+Swift.swift
//  edX
//
//  Created by Saeed Bashir on 8/25/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXCourseInfoViewController {
 
    func enrollInCourse(courseID: String, emailOpt: Bool) {
        
        let environment = OEXRouter.shared().environment
        environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentClicked.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseClicked.rawValue)
        
        guard let _ = OEXSession.shared()?.currentUser else {
            OEXRouter.shared().showSignUpScreen(from: self, completion: {
                self.enrollInCourse(courseID: courseID, emailOpt: emailOpt)
            })
            return;
        }
        
        if let _ = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID) {
            showMainScreen(withMessage: Strings.findCoursesAlreadyEnrolledMessage, courseID: courseID)
            return
        }
        
        let request = CourseCatalogAPI.enroll(courseID: courseID)
        environment.networkManager.taskForRequest(request) {[weak self] response in
            if response.response?.httpStatusCode.is2xx ?? false {
                environment.analytics.trackCourseEnrollment(courseId: courseID, name: AnalyticsEventName.CourseEnrollmentSuccess.rawValue, displayName: AnalyticsDisplayName.EnrolledCourseSuccess.rawValue)
                self?.showMainScreen(withMessage: Strings.findCoursesEnrollmentSuccessfulMessage, courseID: courseID)
            }
            else if response.response?.httpStatusCode.is4xx ?? false {
                self?.showCourseEnrollmentFailureAlert(for: courseID)
            }
            else {
                self?.showOverlay(withMessage: Strings.findCoursesEnrollmentErrorDescription)
            }
        }
    }
    
    func showCourseEnrollmentFailureAlert(for courseID: String) {
        let alertView = UIAlertController().showAlert(withTitle: Strings.findCoursesEnrollmentErrorTitle, message: Strings.findCoursesUnableToEnrollErrorDescription, cancelButtonTitle: Strings.cancel, onViewController: self)
        alertView.addButton(withTitle: Strings.goToWeb) { _ in
            if let url = URL(string: String(format:"%@/courses/%@", OEXRouter.shared().environment.config.apiHostURL()?.absoluteString ?? "", courseID)), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
