//
//  DeepLinkManager.swift
//  edX
//
//  Created by Salman on 02/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit


@objc class DeepLinkManager: NSObject {

    static let sharedInstance = DeepLinkManager()
    
    private override init() {
        super.init()
    }

    func processDeepLink(with params: [String: Any]) {
        let deepLink = DeepLink(dictionary: params)
        guard let deepLinkType = deepLink.type else {
            return
        }
        if isUserLoggedin() {
            navigateToDeepLink(with: deepLinkType, link: deepLink)
        }
        else {
            showLoginScreen()
        }
    }
    
    private func showLoginScreen() {
        if let presentedViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostController(), !(presentedViewController.childViewControllers[0].isKind(of: OEXLoginViewController.self)) {
            presentedViewController.dismiss(animated: false, completion: nil)
        }
        OEXRouter.shared().environment.router?.showLoginScreen(from: nil, completion: nil)
    }
    
    private func isUserLoggedin() -> Bool {
        if let _ = OEXRouter.shared().environment.session.currentUser {
            return true
        }
        else {
            return false
        }
    }
    
    private func navigateToDeepLink(with type: DeepLinkType, link: DeepLink) {
        switch type {
        case .CourseDashboard:
            OEXRouter.shared().showMyCourses(animated: true, pushingCourseWithID: link.courseId)
            break
        case .CourseVideo:
            OEXRouter.shared().showCourseDashboard(with: link.courseId ?? "", type: type)
            break
        case .CourseDiscussion:
            OEXRouter.shared().showCourseDashboard(with: link.courseId ?? "", type: type)
            break
        case .CourseDates:
            OEXRouter.shared().showCourseDashboard(with: link.courseId ?? "", type: type)
            break
        }
    }
}
