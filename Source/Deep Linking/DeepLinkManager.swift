//
//  DeepLinkManager.swift
//  edX
//
//  Created by Salman on 02/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

typealias DismissCompletion = (Bool) -> Void

@objc class DeepLinkManager: NSObject {
    
    @objc static let sharedInstance = DeepLinkManager()
    typealias Environment = OEXSessionProvider & OEXRouterProvider & OEXConfigProvider
    var environment: Environment?
    
    private var topMostViewController: UIViewController? {
        return UIApplication.shared.topMostController()
    }
    
    private override init() {
        super.init()
    }
    
    /// This method process the deep link with response parameters
    @objc func processDeepLink(with params: [String: Any], environment: Environment) {
        // If the banner is being displayed, discard the deep link
        if UIApplication.shared.topMostController() is BannerViewController {
            return
        }

        self.environment = environment
        let deepLink = DeepLink(dictionary: params)
        let type = deepLink.type
        guard type != .none else { return }
        
        navigateToScreen(with: type, link: deepLink)
    }
    
    /// This method process the FCM notification with the link object
    func processNotification(with link: PushLink, environment: Environment) {
        self.environment = environment
        let type = link.type
        guard type != .none else { return }
        
        switch UIApplication.shared.applicationState {
        case .active:
            showNotificationAlert(with: link)
            break
        default:
            navigateToScreen(with: type, link: link)
            break
        }
    }
    
    private func showNotificationAlert(with link: PushLink) {
        guard let title = link.title,
            let message = link.body,
            let topController = topMostViewController
            else { return }
        
        let alertController = UIAlertController().showAlert(withTitle: title, message: message, cancelButtonTitle: Strings.cancel, onViewController: topController)
        alertController.addButton(withTitle: Strings.view) { [weak self] _ in
            self?.navigateToScreen(with: link.type, link: link)
        }
    }
    
    private func showLoginScreen(with link: DeepLink) {
        dismiss() { [weak self] _ in
            self?.environment?.router?.showLoginScreen(completion: {
                self?.navigateToScreen(with: link.type, link: link)
            })
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
            else if segmentType == SegmentOption.degree.rawValue {
                return .degreeDiscovery
            }
        } else if controller is OEXFindCoursesViewController  {
            return .courseDiscovery
        } else if let programsDiscoveryViewController = controller as? ProgramsDiscoveryViewController {
            if programsDiscoveryViewController.viewType == .program {
                return programsDiscoveryViewController.pathId == nil ? .programDiscovery : .programDiscoveryDetail
            }
            else if programsDiscoveryViewController.viewType == .degree {
                return programsDiscoveryViewController.pathId == nil ? .degreeDiscovery : .degreeDiscoveryDetail
            }
        } else if controller is ProgramsViewController {
            return .program
        } else if controller is DiscussionTopicsViewController {
            return .discussions
        } else if controller is ProfileOptionsViewController {
            return .profile
        } else if controller is UserProfileViewController {
            return .userProfile
        }
        
        return .none
    }
    
    private func showCourseDashboardViewController(with link: DeepLink) {
        guard let topViewController = topMostViewController else { return }
        
        if let courseDashboardView = topViewController.parent as? CourseDashboardViewController, courseDashboardView.courseID == link.courseId {
            if !controllerAlreadyDisplayed(for: link.type) {
                courseDashboardView.switchTab(with: link.type, componentID: link.componentID)
                return
            }
        }
        
        dismiss() { [weak self] _ in
            if let topController = self?.topMostViewController {
                self?.environment?.router?.showCourse(with: link, courseID: link.courseId ?? "", from: topController)
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
            if let programDiscoveryViewController = topMostViewController as? ProgramsDiscoveryViewController, let pathId = link.pathID {
                if pathId != programDiscoveryViewController.pathId {
                    programDiscoveryViewController.loadProgramDetails(with: pathId)
                }
            }
            
            return
        }
        
        switch link.type {
        case .courseDetail:
            guard environment?.config.discovery.course.isEnabled ?? false, let courseId = link.courseId else { return }
            if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: .courseDiscovery)
                environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .courseDetail, pathID: courseId, bottomBar: discoveryViewController.bottomBar)
                return
            }
            else if let findCoursesViewController = topMostViewController as? OEXFindCoursesViewController {
                environment?.router?.showDiscoveryDetail(from: findCoursesViewController, type: .courseDetail, pathID: courseId, bottomBar: findCoursesViewController.bottomBar)
                return
            }
            break
        case .programDiscoveryDetail:
            guard environment?.config.discovery.program.isEnabled ?? false, let pathId = link.pathID else { return }
            if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: .programDiscovery)
                environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .programDiscoveryDetail, pathID: pathId, bottomBar: discoveryViewController.bottomBar)
                return
            }
            else if let programsDiscoveryViewController = topMostViewController as? ProgramsDiscoveryViewController {
                environment?.router?.showDiscoveryDetail(from: programsDiscoveryViewController, type: .programDiscoveryDetail, pathID: pathId, bottomBar: programsDiscoveryViewController.bottomBar)
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
        
        case .degreeDiscovery:
            guard environment?.config.discovery.degree.isEnabled ?? false else { return }
            if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: link.type)
                return
            }
            break
            
        case .degreeDiscoveryDetail:
            guard environment?.config.discovery.degree.isEnabled ?? false, let pathId = link.pathID else { return }
             if let discoveryViewController = topMostViewController as? DiscoveryViewController {
                discoveryViewController.switchSegment(with: .degreeDiscoveryDetail)
                environment?.router?.showDiscoveryDetail(from: discoveryViewController, type: .degreeDiscoveryDetail, pathID: pathId, bottomBar: discoveryViewController.bottomBar)
                return
            }
            break
            
        default:
            break
        }
        
        guard let topController = topMostViewController else { return }
        
        let pathId = link.type == .courseDetail ? link.courseId : link.pathID
        
        if isUserLoggedin() {
            dismiss() { [weak self] _ in
                if let topController = self?.topMostViewController {
                    self?.environment?.router?.showDiscoveryController(from: topController, type: link.type, isUserLoggedIn: true , pathID: pathId)
                }
            }
        }
        else {
            if !(topController is DiscoveryViewController), topController.isModal() {
                topController.dismiss(animated: true) { [weak self] in
                    if let topController = self?.topMostViewController {
                        self?.environment?.router?.showDiscoveryController(from: topController, type: link.type, isUserLoggedIn: false , pathID: pathId)
                    }
                }
            }
            else {
                environment?.router?.showDiscoveryController(from: topController, type: link.type, isUserLoggedIn: false , pathID: pathId)
            }
        }
    }
    
    private func showPrograms(with link: DeepLink) {
        if let topController = topMostViewController, let controller = topController as? ProgramsViewController,  controller.type == .detail {
            topController.navigationController?.popViewController(animated: true)
        }
        else if !controllerAlreadyDisplayed(for: link.type) {
            dismiss() { [weak self] _ in
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
            dismiss() { [weak self] _ in
                if let topController = self?.topMostViewController {
                    self?.environment?.router?.showProgram(with: link.type, url: url, from: topController)
                }
            }
        }
    }

    // Profile screen having different options like video settings, faq, support email
    private func showProfile(with link: DeepLink, completion: ((_ success: Bool) -> ())? = nil) {
        guard let topViewController = topMostViewController else {
            completion?(false)
            return
        }

        // We can't use the controllerAlreadyDisplayed method here to check either the user is already on the user profile screen or not
        // Because the user could have accessed the UserProfileViewController screen from the discussion forums
        // From the discussion forums, the UserProfileViewController screen will be for a different user so we need to show the profile screen of the logged-in user
        // if the stackController is equals to the ProfileOptionsViewController, it means the user profile screen opens from new profile (settings) screen
        if topViewController is ProfileOptionsViewController {
            completion?(true)
            return
        }

        if topViewController is UserProfileViewController || topViewController is UserProfileEditViewController || topViewController is JSONFormViewController<String> || topViewController is JSONFormBuilderTextEditorViewController {
            if let viewController = topViewController.navigationController?.viewControllers.first(where: {$0 is ProfileOptionsViewController}) {
                topViewController.navigationController?.popToViewController(viewController, animated: true)
                topViewController.navigationController?.navigationBar.applyDefaultNavbarColorScheme()
                completion?(true)
            }
            else {
                environment?.router?.showProfile(controller: topViewController, completion: completion)
            }
        }
        else {
            dismiss() { [weak self] dismiss in
                // dissmiss will be false if the notice banner is on screen while dismissing the presented controller
                if !dismiss { return }

                if let topViewController = self?.topMostViewController {
                    self?.environment?.router?.showProfile(controller: topViewController, completion: completion)
                }
            }
        }
    }
    
    private func showUserProfile(with link: DeepLink) {
        guard let topViewController = topMostViewController,
              let username = environment?.session.currentUser?.username else { return }

        // We can't use the controllerAlreadyDisplayed method here to check either the user is already on the user profile screen or not
        // Because the user could have accessed the UserProfileViewController screen from the discussion forums
        // From the discussion forums, the UserProfileViewController screen will be for a different user so we need to show the profile screen of the logged-in user
        // if the stackController is equals to the ProfileOptionsViewController, it means the user profile screen opens from new profile (settings) screen
        let stackController = topViewController.navigationController?.viewControllers.first
        if topViewController is UserProfileViewController && stackController is ProfileOptionsViewController {
            return
        }

        func showView(modal: Bool) {
            environment?.router?.showProfileForUsername(controller: topMostViewController, username: username, editable: false, modal: modal)
        }
        
        if topViewController is ProfileOptionsViewController {
            showView(modal: false)
        } else if topViewController is UserProfileEditViewController || topViewController is JSONFormViewController<String> || topViewController is JSONFormBuilderTextEditorViewController {
            if let viewController = topViewController.navigationController?.viewControllers.first(where: {$0 is UserProfileViewController}) {
                topViewController.navigationController?.popToViewController(viewController, animated: true)
            }
        }
        else {
            dismiss() { [weak self] dismiss in
                // dissmiss will be false if the notice banner is on screen while dismissing the presented controller
                if !dismiss { return }

                self?.showProfile(with: link) { success in
                    if success {
                        self?.showUserProfile(with: link)
                    }
                }
            }
        }
    }
    
    private func showDiscussionTopic(with link: DeepLink) {
        guard let courseId = link.courseId,
            let topicID = link.topicID,
            let topController = topMostViewController else { return }
        
        var isControllerAlreadyDisplayed : Bool {
            guard let postController = topMostViewController as? PostsViewController else { return false }
            return postController.topicID == link.topicID
        }
        
        func showDiscussionPosts() {
            if let topController = topMostViewController {
                environment?.router?.showDiscussionPosts(from: topController, courseID: courseId, topicID: topicID)
            }
        }
        
        if let postController = topController as? PostsViewController, postController.topicID != link.topicID {
            postController.navigationController?.popViewController(animated: true)
            showDiscussionPosts()
        }
        else {
            dismiss() { [weak self] _ in
                guard let topController = self?.topMostViewController, !isControllerAlreadyDisplayed else { return }
                
                if let courseDashboardController = topController as? CourseDashboardViewController, courseDashboardController.courseID == link.courseId {
                    courseDashboardController.switchTab(with: link.type)
                }
                else {
                    self?.showCourseDashboardViewController(with: link)
                }
                
                showDiscussionPosts()
            }
        }
    }
    
    private func showDiscussionResponses(with link: DeepLink, completion: (() -> Void)? = nil) {
        guard let courseId = link.courseId,
            let threadID = link.threadID,
            let topController = topMostViewController else { return }
        
        var isControllerAlreadyDisplayed: Bool {
            guard let discussionResponseController = topMostViewController as? DiscussionResponsesViewController else { return false }
            return discussionResponseController.threadID == link.threadID
        }
        
        func showResponses() {
            if let topController = topMostViewController {
                environment?.router?.showDiscussionResponses(from: topController, courseID: courseId, threadID: threadID, isDiscussionBlackedOut: false, completion: completion)
            }
        }
        
        if let discussionResponseController = topController as? DiscussionResponsesViewController, discussionResponseController.threadID != link.threadID  {
            discussionResponseController.navigationController?.popViewController(animated: true)
            showResponses()
        }
        else {
            dismiss() { [weak self] _ in
                guard let topController = self?.topMostViewController, !isControllerAlreadyDisplayed else { return }
                if let courseDashboardController = topController as? CourseDashboardViewController, courseDashboardController.courseID == link.courseId {
                    courseDashboardController.switchTab(with: link.type)
                }
                else if let postViewController = topController as? PostsViewController, postViewController.topicID != link.topicID {
                    postViewController.navigationController?.popViewController(animated: true)
                }
                self?.showDiscussionTopic(with: link)
                showResponses()
            }
        }
    }
    
    private func showdiscussionComments(with link: DeepLink) {
        
        guard let courseID = link.courseId,
            let commentID = link.commentID,
            let threadID = link.threadID,
            let topController = topMostViewController else { return }
        
        var isControllerAlreadyDisplayed: Bool {
            guard let discussionCommentViewController = topMostViewController as? DiscussionCommentsViewController else { return false}
            return discussionCommentViewController.commentID == commentID
        }
        
        var isResponseControllerDisplayed: Bool {
            guard let discussionResponseController = topMostViewController as? DiscussionResponsesViewController else { return false }
            return discussionResponseController.threadID == link.threadID
        }
        
        func showComment() {
            if let topController = topMostViewController, let discussionResponseController = topController as? DiscussionResponsesViewController {
                    environment?.router?.showDiscussionComments(from: discussionResponseController, courseID: courseID, commentID: commentID, threadID:threadID)
                    discussionResponseController.navigationController?.delegate = nil
            }
        }
        
        if let discussionCommentController = topController as? DiscussionCommentsViewController, discussionCommentController.commentID != commentID {
            discussionCommentController.navigationController?.popViewController(animated: true)
            showComment()
        }
        else {
             dismiss() { [weak self] _ in
                guard !isControllerAlreadyDisplayed else { return }
                if isResponseControllerDisplayed {
                    showComment()
                }
                else {
                    self?.showDiscussionResponses(with: link) {
                        showComment()
                    }
                }
            }
        }
    }
    
    private func showCourseHandout(with link: DeepLink) {
        
        var controllerAlreadyDisplayed: Bool {
            if let topController = topMostViewController, let courseHandoutController = topController as? CourseHandoutsViewController, courseHandoutController.courseID == link.courseId {
                return true
            }
            return false
        }
        
        func showHandout() {
            if let topController = topMostViewController {
                environment?.router?.showHandoutsFromController(controller: topController, courseID: link.courseId ?? "")
            }
        }
        
        guard !controllerAlreadyDisplayed else { return }
        
         dismiss() { [weak self] _ in
            if let topController = self?.topMostViewController {
                self?.environment?.router?.showCourse(with: link, courseID: link.courseId ?? "", from: topController)
            }
            showHandout()
        }
    }
    
    private func showCourseAnnouncement(with link: DeepLink) {
        
        var controllerAlreadyDisplayed: Bool {
            if let topController = topMostViewController, let courseAnnouncementsViewController = topController as? CourseAnnouncementsViewController, courseAnnouncementsViewController.courseID == link.courseId {
                return true
            }
            return false
        }
        
        func showAnnouncement() {
            if let topController = topMostViewController {
                environment?.router?.showAnnouncment(from: topController, courseID: link.courseId ?? "")
            }
        }
        
        guard !controllerAlreadyDisplayed else { return }
        
        dismiss() { [weak self] _ in
            if let topController = self?.topMostViewController {
                self?.environment?.router?.showCourse(with: link, courseID: link.courseId ?? "", from: topController)
            }
            showAnnouncement()
        }
    }
    
    
    private func controllerAlreadyDisplayed(for type: DeepLinkType) -> Bool {
        guard let topViewController = topMostViewController else { return false }
        
        return linkType(for: topViewController) == type
    }
    
    private func dismiss(completion: @escaping DismissCompletion) {
        if let rootController = UIApplication.shared.keyWindow?.rootViewController, rootController.presentedViewController != nil {
            if let _ = UIApplication.shared.topMostController() as? BannerViewController {
                completion(false)
                return
            }
            rootController.dismiss(animated: false) {
                completion(true)
            }
        }
        else {
            completion(true)
        }
    }
    
    private func isDiscovery(type: DeepLinkType) -> Bool {
        return (type == .courseDiscovery || type == .courseDetail || type == .programDiscovery
            || type == .programDiscoveryDetail || type == .degreeDiscovery || type == .degreeDiscoveryDetail)
    }
    
    private func navigateToScreen(with type: DeepLinkType, link: DeepLink) {
        
        if isDiscovery(type: type) {
            showDiscovery(with: link)
        }
            
        else if !isUserLoggedin() {
            showLoginScreen(with: link)
            return
        }
        
        switch type {
        case .courseDashboard, .courseVideos, .discussions, .courseDates, .courseComponent:
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
        case .profile:
            showProfile(with: link)
            break
        case .userProfile:
            showUserProfile(with: link)
            break
        case .discussionTopic:
            showDiscussionTopic(with: link)
            break
        case .discussionPost:
            showDiscussionResponses(with: link)
            break
        case .discussionComment:
            showdiscussionComments(with: link)
        case .courseHandout:
            showCourseHandout(with: link)
            break
        case .courseAnnouncement:
            showCourseAnnouncement(with: link)
            break
        default:
            break
        }
    }
}
