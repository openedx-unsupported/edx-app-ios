//
//  DeepLinkManager.swift
//  edX
//
//  Created by Salman on 02/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

typealias DismissCompletion = () -> Void

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
        guard let deepLinkType = deepLink.type, deepLinkType != .None else { return }
        
        if isUserLoggedin() {
            navigateToDeepLink(with: deepLinkType, link: deepLink)
        }
        else {
            showLoginScreen()
        }
    }
    
    private func showLoginScreen() {
        guard let topViewController = topMostViewController,
            !(topViewController is OEXLoginViewController) else { return }
    
        dismiss() { [weak self] in
            self?.environment?.router?.showLoginScreen(from: nil, completion: nil)
        }
    }
        
    private func isUserLoggedin() -> Bool {
        return environment?.session.currentUser != nil
    }
    
    private func linkType(for controller: UIViewController) -> DeepLinkType {
        if let courseOutlineViewController = controller as? CourseOutlineViewController {
            return courseOutlineViewController.courseOutlineMode == .full ? .CourseDashboard : .CourseVideos
        }
        else if controller is ProgramsViewController {
            return .Programs
        } else if controller is DiscussionTopicsViewController {
            return .Discussions
        } else if controller is AccountViewController {
            return .Account
        }
        
        return .None
    }
    
    private func showCourseDashboardViewController(with link: DeepLink) {
        guard let topViewController = topMostViewController else { return }
        
        if let courseDashboardView = topViewController.parent as? CourseDashboardViewController, courseDashboardView.courseID == link.courseId {
            if !controllerAlreadyDisplayed(for: link.type ?? .None) {
                courseDashboardView.switchTab(with: link.type ?? .None)
            }
        } else {
            dismiss() { [weak self] in
                self?.environment?.router?.showCourseWithDeepLink(type: link.type ?? .None, courseID: link.courseId ?? "")
            }
        }
    }
    
    private func showPrograms(with link: DeepLink) {
        guard !controllerAlreadyDisplayed(for: link.type ?? .None) else { return}
        
        dismiss() { [weak self] in
            self?.environment?.router?.showPrograms(with: link.type ?? .None)
        }
    }

    private func showAccountViewController(with link: DeepLink) {
        guard !controllerAlreadyDisplayed(for: link.type ?? .None) else { return}
    
        dismiss() { [weak self] in
            if let topViewController = self?.topMostViewController {
                self?.environment?.router?.showAccount(controller:topViewController, modalTransitionStylePresent: true)
            }
        }
    }
    
    private var topMostViewController: UIViewController? {
        return UIApplication.shared.topMostController()
    }
    
    private func controllerAlreadyDisplayed(for type: DeepLinkType) -> Bool {
        guard let topViewController = topMostViewController else { return false }

        return linkType(for: topViewController) == type
    }
    
    private func dismiss(completion: @escaping DismissCompletion) {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController, rootController.presentedViewController != nil {
            rootController.dismiss(animated: false, completion: completion)
        }
        else {
            completion()
        }
    }

    private func navigateToDeepLink(with type: DeepLinkType, link: DeepLink) {
        switch type {
        case .CourseDashboard, .CourseVideos, .Discussions:
            showCourseDashboardViewController(with: link)
            break
        case .Programs:
            guard environment?.config.programConfig.enabled ?? false else { return }
            showPrograms(with: link)
        case .Account:
            showAccountViewController(with: link)
        break
        default:
            break
        }
    }
}
