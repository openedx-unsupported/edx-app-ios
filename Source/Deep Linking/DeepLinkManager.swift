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
    typealias Environment = OEXSessionProvider & OEXRouterProvider & OEXConfigProvider
    var environment: Environment?
    
    private override init() {
        super.init()
    }

    func processDeepLink(with params: [String: Any], environment: Environment) {
        self.environment = environment
        let deepLink = DeepLink(dictionary: params)
        guard let deepLinkType = deepLink.type, deepLinkType != .None else {
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
        environment?.router?.showLoginScreen(from: nil, completion: nil)
    }
    
    private func isUserLoggedin() -> Bool {
        return environment?.session.currentUser != nil
    }
    
    private func dismissPresentedView() {
        if let presentedViewController = UIApplication.shared.keyWindow?.rootViewController?.topMostController(), presentedViewController.isModal() {
            presentedViewController.dismiss(animated: false, completion: nil)
        }
    }
    
    private func navigateToDeepLink(with type: DeepLinkType, link: DeepLink) {
        switch type {
        case .CourseDashboard, .CourseVideos, .Discussions:
            dismissPresentedView()
            environment?.router?.showCourseWithDeepLink(type: link.type ?? .None, courseID: link.courseId ?? "")
            break
        case .Programs:
            guard environment?.config.programConfig.enabled ?? false else { return }
            dismissPresentedView()
            environment?.router?.showPrograms(with: type)
        default:
            break
        }
    }
}
