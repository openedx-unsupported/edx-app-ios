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
    
    private var topMostViewController: UIViewController? {
        return UIApplication.shared.topMostController()
    }
    
    private override init() {
        super.init()
    }

    func processDeepLink(with params: [String: Any], environment: Environment) {
        self.environment = environment
        let deepLink = DeepLink(dictionary: params)
        let deepLinkType = deepLink.type
        guard deepLinkType != .none else { return }
        
        navigateToDeepLink(with: deepLinkType, link: deepLink)
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
            return courseOutlineViewController.courseOutlineMode == .full ? .courseDashboard : .courseVideos
        }
        else if controller is OEXCourseInfoViewController {
            return .courseDetail
        } else if let discoveryViewController = controller as? DiscoveryViewController {
            let segmentType = discoveryViewController.segmentType(of: discoveryViewController.segmentedControl.selectedSegmentIndex)
            if segmentType == SegmentOption.program.rawValue {
                return .programDiscovery
            }
            else if segmentType == SegmentOption.course.rawValue {
                return .courseDiscovery
            }
        } else if controller is OEXFindCoursesViewController  {
            return .courseDiscovery
        } else if let programsDiscoveryViewController = controller as? ProgramsDiscoveryViewController {
            return programsDiscoveryViewController.pathId == nil ? .programDiscovery : .programDetail
        } else if controller is ProgramsViewController {
            return .programs
        } else if controller is DiscussionTopicsViewController {
            return .discussions
        } else if controller is AccountViewController {
            return .account
        }
        
        return .none
    }
    
    private func showCourseDashboardViewController(with link: DeepLink) {
        guard let topViewController = topMostViewController else { return }
        
        if let courseDashboardView = topViewController.parent as? CourseDashboardViewController, courseDashboardView.courseID == link.courseId {
            if !controllerAlreadyDisplayed(for: link.type) {
                courseDashboardView.switchTab(with: link.type)
            }
        } else {
            dismiss() { [weak self] in
                self?.environment?.router?.showCourseWithDeepLink(type: link.type, courseID: link.courseId ?? "")
            }
        }
    }
    
    private func showDiscovery(with link: DeepLink) {
        
        guard !controllerAlreadyDisplayed(for: link.type) else {
            
            // Course discovery detail if already loaded
            if let courseInfoController = topMostViewController as? OEXCourseInfoViewController,
                let pathId = link.courseId {
                courseInfoController.loadCourseInfo(with: pathId, forceLoad: false)
            }
            
            // Program discovery detail if already loaded
            if let programDiscoveryViewController = topMostViewController as? ProgramsDiscoveryViewController,
                let pathId = link.courseId {
                programDiscoveryViewController.loadProgramDetails(with: pathId)
            }
            
            return
        }
        
        switch link.type {
        case .courseDetail:
            guard environment?.config.discovery.course.isEnabled ?? false, let courseId = link.courseId else { return }
                if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                    discoveryViewController.switchSegment(with: .courseDiscovery)
                    environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .courseDetail, coursePathID: courseId, bottomBar: discoveryViewController.bottomBar)
                    return
                }
                else if let findCoursesViewController = topMostViewController as? OEXFindCoursesViewController {
                    environment?.router?.showDiscoveryDetail(from: findCoursesViewController, type: .courseDetail, coursePathID: courseId, bottomBar: findCoursesViewController.bottomBar)
                    return
                }
            break
        case .programDetail:
            guard environment?.config.discovery.program.isEnabled ?? false, let courseId = link.courseId else { return }
                if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                    discoveryViewController.switchSegment(with: .programDiscovery)
                    environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .programDetail, coursePathID: courseId, bottomBar: discoveryViewController.bottomBar)
                    return
                }
                else if let programsDiscoveryViewController = topMostViewController as? ProgramsDiscoveryViewController {
                    environment?.router?.showDiscoveryDetail(from: programsDiscoveryViewController, type: .programDetail, coursePathID: courseId, bottomBar: programsDiscoveryViewController.bottomBar)
                    return
                }
            break
        case .programDiscovery:
            guard environment?.config.discovery.program.isEnabled ?? false else { return }
            if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: link.type)
                return
            }
            break
        case .courseDiscovery:
            guard environment?.config.discovery.course.isEnabled ?? false else { return }
            if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: link.type)
                return
            }
            break
            
        default:
            break
        }
        
        dismiss() { [weak self] in
            self?.environment?.router?.showDiscoveryController(with: link.type, isUserLoggedIn: self?.isUserLoggedin() ?? false, coursePathID: link.courseId)
        }
    }
    
    private func showPrograms(with link: DeepLink) {
        guard !controllerAlreadyDisplayed(for: link.type) else { return}
        
        dismiss() { [weak self] in
            self?.environment?.router?.showPrograms(with: link.type)
        }
    }

    private func showAccountViewController(with link: DeepLink) {
        guard !controllerAlreadyDisplayed(for: link.type) else { return}
    
        dismiss() { [weak self] in
            if let topViewController = self?.topMostViewController {
                self?.environment?.router?.showAccount(controller:topViewController, modalTransitionStylePresent: true)
            }
        }
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
    
    private func isDiscovery(type: DeepLinkType) -> Bool {
        return (type == .courseDiscovery || type == .courseDetail || type == .programDiscovery || type == .programDetail)
    }

    private func navigateToDeepLink(with type: DeepLinkType, link: DeepLink) {
        
        if isDiscovery(type: type) {
            showDiscovery(with: link)
        }
        
        else if !isUserLoggedin() {
            showLoginScreen()
            return
        }
        
        switch type {
        case .courseDashboard, .courseVideos, .discussions:
            showCourseDashboardViewController(with: link)
            break
        case .programs:
            guard environment?.config.programConfig.enabled ?? false else { return }
            showPrograms(with: link)
            break
        case .account:
            showAccountViewController(with: link)
            break
        default:
            break
        }
    }
}
