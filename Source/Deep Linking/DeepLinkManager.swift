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
            return programsDiscoveryViewController.pathId == nil ? .programDiscovery : .programDiscoveryDetail
        } else if controller is ProgramsViewController {
            return .program
        } else if controller is DiscussionTopicsViewController {
            return .discussions
        } else if controller is AccountViewController {
            return .account
        } else if controller is UserProfileViewController {
            return .profile
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
        case .programDiscoveryDetail:
            guard environment?.config.discovery.program.isEnabled ?? false, let pathId = link.pathID else { return }
                if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                    discoveryViewController.switchSegment(with: .programDiscovery)
                    environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .programDiscoveryDetail, coursePathID: pathId, bottomBar: discoveryViewController.bottomBar)
                    return
                }
                else if let programsDiscoveryViewController = topMostViewController as? ProgramsDiscoveryViewController {
                    environment?.router?.showDiscoveryDetail(from: programsDiscoveryViewController, type: .programDiscoveryDetail, coursePathID: pathId, bottomBar: programsDiscoveryViewController.bottomBar)
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
        if let topController = topMostViewController, let controller = topController as? ProgramsViewController,  controller.type == .detail {
            topController.navigationController?.popViewController(animated: true)
        }
        else if !controllerAlreadyDisplayed(for: link.type) {
            dismiss() { [weak self] in
                if let topController = self?.topMostViewController {
                    self?.environment?.router?.showProgram(with: link.type, from: topController)
                }
            }
        }
    }

    private func showProgramDetail(with link: DeepLink) {
        guard !controllerAlreadyDisplayed(for: link.type),
            let myProgramDetailURL = environment?.config.programConfig.programDetailURLTemplate,
            let pathID = link.pathID,
            let url = URL(string: myProgramDetailURL.replacingOccurrences(of: URIString.pathPlaceHolder.rawValue, with: pathID))
            else { return}
        
             if let topController = topMostViewController, let controller = topController as? ProgramsViewController {
                if controller.type == .base {
                    environment?.router?.showProgramDetails(with: url, from: topController)
                } else if controller.type == .detail && controller.programsURL != url {
                    controller.loadPrograms(with: url)
                }
            }
            else {
                dismiss() { [weak self] in
                    if let topController = self?.topMostViewController {
                        self?.environment?.router?.showProgram(with: link.type, url: url, from: topController)
                    }
                }
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
    
    private func showProfile(with link: DeepLink) {
        guard let topViewController = topMostViewController, let username = environment?.session.currentUser?.username else { return }

        func showView(modal: Bool) {
            environment?.router?.showProfileForUsername(controller: topMostViewController, username: username, editable: false, modal: modal)
        }

        if topViewController is AccountViewController {
            showView(modal: false)
        }
        else if topViewController is UserProfileEditViewController || topViewController is JSONFormViewController<String> || topViewController is JSONFormBuilderTextEditorViewController {
            if let viewController = topViewController.navigationController?.viewControllers.first(where: {$0 is UserProfileViewController}) {
                topViewController.navigationController?.popToViewController(viewController, animated: true)
            }
        }
        else if !controllerAlreadyDisplayed(for: link.type) {
            dismiss() {
                showView(modal: true)
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
        return (type == .courseDiscovery || type == .courseDetail || type == .programDiscovery || type == .programDiscoveryDetail)
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
        case .program:
            guard environment?.config.programConfig.enabled ?? false else { return }
            showPrograms(with: link)
            break
        case .programDetail:
            guard environment?.config.programConfig.enabled ?? false else { return }
            showProgramDetail(with: link)
            break
        case .account:
            showAccountViewController(with: link)
            break
        case .profile:
            showProfile(with: link)
            break
        default:
            break
        }
    }
}
