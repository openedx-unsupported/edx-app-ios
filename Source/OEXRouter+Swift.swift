//
//  OEXRouter+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 5/7/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import WebKit

// The router is an indirection point for navigation throw our app.

// New router logic should live here so it can be written in Swift.
// We should gradually migrate the existing router class here and then
// get rid of the objc version

public enum CourseHTMLBlockSubkind {
    case Base
    case Problem
    case OpenAssesment
    case DragAndDrop
    case WordCloud
    case LTIConsumer
}

enum CourseBlockDisplayType {
    case Unknown
    case Outline
    case Unit
    case Video
    case HTML(CourseHTMLBlockSubkind)
    case Discussion(DiscussionModel)
    
    var isUnknown : Bool {
        switch self {
        case .Unknown: return true
        default: return false
        }
    }
}

extension CourseBlock {

    var displayType : CourseBlockDisplayType {
        switch self.type {
        case .Unknown(_), .HTML: return multiDevice ? .HTML(.Base) : .Unknown
        case .Problem: return multiDevice ? .HTML(.Problem) : .Unknown
        case .OpenAssesment: return multiDevice ? .HTML(.OpenAssesment) : .Unknown
        case .DragAndDrop: return multiDevice ? .HTML(.DragAndDrop) : .Unknown
        case .WordCloud: return multiDevice ? .HTML(.WordCloud) : .Unknown
        case .LTIConsumer: return multiDevice ? .HTML(.LTIConsumer) : .Unknown
        case .Course: return .Outline
        case .Chapter: return .Outline
        case .Section: return .Outline
        case .Unit: return .Unit
        case let .Video(summary): return (summary.isSupportedVideo) ? .Video : .Unknown
        case let .Discussion(discussionModel): return .Discussion(discussionModel)
        }
    }
}

extension OEXRouter {
    func showCoursewareForCourseWithID(courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(blockID: nil, type: CourseBlockDisplayType.Outline, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID?, initialChildID : CourseBlockID?, forMode mode: CourseOutlineMode? = .full) -> CourseContentPageViewController {
        let contentPageController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: blockID, initialChildID: initialChildID, forMode: mode ?? .full)
        return contentPageController
    }
    
    func navigateToComponentScreen(from controller: UIViewController, courseID: CourseBlockID, componentID: CourseBlockID, completion: ((UIViewController) -> Void)? = nil) {
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        guard let childBlock = courseQuerier.blockWithID(id: componentID).firstSuccess().value,
              let unitBlock = courseQuerier.parentOfBlockWith(id: childBlock.blockID, type: .Unit).firstSuccess().value,
              let sectionBlock = courseQuerier.parentOfBlockWith(id: childBlock.blockID, type: .Section).firstSuccess().value,
              let chapterBlock = courseQuerier.parentOfBlockWith(id: childBlock.blockID, type: .Chapter).firstSuccess().value else {
            Logger.logError("ANALYTICS", "Unable to load block: \(componentID)")
            return
        }
        
        var outlineViewController: UIViewController
        
        if controller is CourseOutlineViewController {
            outlineViewController = controller
        } else {
            guard let dashboardController = controller.navigationController?.viewControllers.first(where: { $0 is CourseDashboardViewController}) as? CourseDashboardViewController else { return }
            dashboardController.switchTab(with: .courseDashboard)
            guard let outlineController = dashboardController.currentVisibleController as? CourseOutlineViewController else { return }
            outlineViewController = outlineController
        }
        
        showContainerForBlockWithID(blockID: sectionBlock.blockID, type: sectionBlock.displayType, parentID: chapterBlock.blockID, courseID: courseID, fromController: outlineViewController) { [weak self] visibleController in
            self?.showContainerForBlockWithID(blockID: childBlock.blockID, type: childBlock.displayType, parentID: unitBlock.blockID, courseID: courseID, fromController: visibleController, completion: completion)
        }
    }
    
    func showCourseUnknownBlock(blockID: CourseBlockID?, courseID: CourseBlockID, fromController controller: UIViewController) {
        let unsupportedController = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
        controller.navigationController?.pushViewController(unsupportedController, animated: true)
    }
    
    func showContainerForBlockWithID(blockID: CourseBlockID?, type: CourseBlockDisplayType, parentID: CourseBlockID?, courseID: CourseBlockID, fromController controller: UIViewController, forMode mode: CourseOutlineMode? = .full, completion: ((UIViewController) -> Void)? = nil) {
        switch type {
        case .Outline:
            fallthrough
        case .Unit:
            let outlineController = controllerForBlockWithID(blockID: blockID, type: type, courseID: courseID, forMode: mode)
            controller.navigationController?.pushViewController(outlineController, animated: true, completion: completion)
        case .HTML:
            fallthrough
        case .Video:
            fallthrough
        case .Unknown:
            let pageController = unitControllerForCourseID(courseID: courseID, blockID: parentID, initialChildID: blockID, forMode: mode)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true, completion: completion)
        case .Discussion:
            let pageController = unitControllerForCourseID(courseID: courseID, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true, completion: completion)
        }
    }
    
    func showCelebratoryModal(fromController controller: UIViewController, courseID: String) -> CelebratoryModalViewController {
        let celebratoryModalView = CelebratoryModalViewController(courseID: courseID, environment: environment)
        celebratoryModalView.modalPresentationStyle = .overCurrentContext
        celebratoryModalView.modalTransitionStyle = .crossDissolve
        controller.present(celebratoryModalView, animated: false, completion: nil)
        return celebratoryModalView
    }

    private func controllerForBlockWithID(blockID: CourseBlockID?, type: CourseBlockDisplayType, courseID: String, forMode mode: CourseOutlineMode? = .full, gated: Bool? = false, shouldCelebrationAppear: Bool = false) -> UIViewController {

        if gated ?? false {
            return CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
        }
        
        switch type {
            case .Outline:
                let outlineController = CourseOutlineViewController(environment: self.environment, courseID: courseID, rootID: blockID, forMode: mode)
                return outlineController
        case .Unit:
            return unitControllerForCourseID(courseID: courseID, blockID: blockID, initialChildID: nil, forMode: mode)
        case .HTML(let subkind):
            let controller = HTMLBlockViewController(blockID: blockID, courseID: courseID, environment: environment, subkind: subkind)
            return controller
        case .Video:
            let controller = VideoBlockViewController(environment: environment, blockID: blockID, courseID: courseID, shouldCelebrationAppear: shouldCelebrationAppear)
            return controller
        case .Unknown:
            let controller = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case let .Discussion(discussionModel):
            let controller = DiscussionBlockViewController(blockID: blockID, courseID: courseID, topicID: discussionModel.topicID, environment: environment)
            return controller
        }
    }
    
    func controllerForBlock(block : CourseBlock, courseID : String, shouldCelebrationAppear: Bool = false) -> UIViewController {
        return controllerForBlockWithID(blockID: block.blockID, type: block.displayType, courseID: courseID, gated: block.isGated, shouldCelebrationAppear: shouldCelebrationAppear)
    }
    
    @objc(showMyCoursesAnimated:pushingCourseWithID:) func showMyCourses(animated: Bool = true, pushingCourseWithID courseID: String? = nil) {
        let controller = EnrolledTabBarViewController(environment: environment)
        showContentStack(withRootController: controller, animated: animated)
        if let courseID = courseID {
            showCourseWithID(courseID: courseID, fromController: controller, animated: false)
        }
    }

   @objc func showEnrolledTabBarView() {
        let controller = EnrolledTabBarViewController(environment: environment)
        showContentStack(withRootController: controller, animated: false)
    }
    
    func showCourseDates(controller:UIViewController, courseID: String) {
        let courseDates = CourseDatesViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(courseDates, animated: true)
    }
    
    func showCourseVideos(controller:UIViewController, courseID: String) {
        showContainerForBlockWithID(blockID: nil, type: CourseBlockDisplayType.Outline, parentID: nil, courseID : courseID, fromController: controller, forMode: .video)
    }
    
    func showDatesTabController(controller: UIViewController) {
        if let dashboardController = controller as? CourseDashboardViewController {
            dashboardController.switchTab(with: .courseDates)
        } else if let dashboardController = controller.navigationController?.viewControllers.first(where: { $0 is CourseDashboardViewController}) as? CourseDashboardViewController {
            controller.navigationController?.popToViewController(dashboardController, animated: false)
            dashboardController.switchTab(with: .courseDates)
        }
    }
    
    // MARK: Deep Linking
    //Method can be use to navigate on particular tab of course dashboard with deep link type
    func showCourse(with deeplink: DeepLink, courseID: String, from controller: UIViewController) {
        let courseDashboardController = controller.navigationController?.viewControllers.first(where: { $0.isKind(of: CourseDashboardViewController.self) })
        
        if let dashboardController = courseDashboardController as? CourseDashboardViewController, dashboardController.courseID == deeplink.courseId {
            controller.navigationController?.setToolbarHidden(true, animated: false)
            controller.navigationController?.popToViewController(dashboardController, animated: true)
            dashboardController.switchTab(with: deeplink.type, componentID: deeplink.componentID)
        } else if let enrolledTabBarController = controller.find(viewController: EnrolledTabBarViewController.self) {
            if let courseDashboardController = courseDashboardController {
                courseDashboardController.navigationController?.popToRootViewController(animated: true) { [weak self] in
                    let switchedViewController = enrolledTabBarController.switchTab(with: deeplink.type)
                    self?.showCourseWithID(courseID: courseID, fromController: switchedViewController, animated: true) { controller in
                        guard let dashboardController = controller as? CourseDashboardViewController else { return }
                        dashboardController.switchTab(with: deeplink.type, componentID: deeplink.componentID)
                    }
                }
            } else {
                let switchedViewController = enrolledTabBarController.switchTab(with: deeplink.type)
                if let switchedViewController = switchedViewController as? LearnContainerViewController {
                    switchedViewController.navigationController?.popToRootViewController(animated: true) {
                        switchedViewController.switchTo(component: .courses)
                    }
                }
                showCourseWithID(courseID: courseID, fromController: switchedViewController, animated: true) { controller in
                    guard let dashboardController = controller as? CourseDashboardViewController else { return }
                    dashboardController.switchTab(with: deeplink.type, componentID: deeplink.componentID)
                }
            }
        }
    }

    func showProgram(with type: DeepLinkType, url: URL? = nil, from controller: UIViewController) {
        let tabbarController = controller.find(viewController: EnrolledTabBarViewController.self)
        if let learnController = tabbarController?.switchTab(with: type) as? LearnContainerViewController {
            popToRoot(controller: learnController)
            if let programsViewController = learnController.switchTo(component: .programs) as? ProgramsViewController,
            let url = url {
                showProgramDetails(with: url, from: programsViewController)
            }
        }
    }
    
    func showAnnouncment(from controller : UIViewController, courseID : String) {
        let announcementViewController =  CourseAnnouncementsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(announcementViewController, animated: true)
    }
    
    private func popToRoot(controller: UIViewController, completion: (() -> Void)? = nil) {
        controller.navigationController?.setToolbarHidden(true, animated: false)
        controller.navigationController?.popToRootViewController(animated: true, completion: completion)
    }
    
    func showDiscoveryController(from controller: UIViewController, type: DeepLinkType, isUserLoggedIn: Bool, pathID: String?) {
        let bottomBar = BottomBarView(environment: environment)
        var discoveryController = discoveryViewController(bottomBar: bottomBar, searchQuery: nil)
        if isUserLoggedIn {
        
            // Pop out all views and switches enrolledCourses tab on the bases of link type
            if let enrolledTabBarView = controller.find(viewController: EnrolledTabBarViewController.self) {
                popToRoot(controller: enrolledTabBarView)
                discoveryController = enrolledTabBarView.switchTab(with: type)
            }
            else {
                
                //Create new stack of views and switch tab
                let enrolledTabController = EnrolledTabBarViewController(environment: environment)
                showContentStack(withRootController: enrolledTabController, animated: false)
                discoveryController = enrolledTabController.switchTab(with: type)
            }
        }
        else {
            if let controllers = controller.navigationController?.viewControllers, let discoveryView = controllers.first as? DiscoveryViewController {
                popToRoot(controller: controller)
                discoveryController = discoveryView
            }
            else if let discoveryController = discoveryController {
                showControllerFromStartupScreen(controller: discoveryController)
            }
        }
        
        // If the pathID is given the detail view will open
        if let pathID = pathID, let discoveryController = discoveryController {
            showDiscoveryDetail(from: discoveryController, type: type, pathID: pathID, bottomBar: bottomBar)
        }
    }
    
     func showDiscoveryDetail(from controller: UIViewController, type: DeepLinkType, pathID: String, bottomBar: UIView?) {
        if type == .discoveryCourseDetail {
            showCourseDetails(from: controller, with: pathID, bottomBar: bottomBar)
        }
        else if type == .discoveryProgramDetail {
            showProgramDetail(from: controller, with: pathID, bottomBar: bottomBar)
        }
    }

    func showDiscussionResponsesFromViewController(controller: UIViewController, courseID : String, thread : DiscussionThread, isDiscussionBlackedOut: Bool) {
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.thread = thread
        responsesViewController.isDiscussionBlackedOut = isDiscussionBlackedOut
        
        controller.navigationController?.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionResponses(from controller: UIViewController, courseID: String, threadID: String, isDiscussionBlackedOut: Bool, completion: (()->Void)?) {
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.threadID = threadID
        responsesViewController.isDiscussionBlackedOut = isDiscussionBlackedOut
        controller.navigationController?.delegate = self
        if let completion = completion {
            controller.navigationController?.pushViewController(viewController: responsesViewController, completion: completion)
        } else {
            controller.navigationController?.pushViewController(responsesViewController, animated: true)
        }
    }
    
    func showDiscussionComments(from controller: UIViewController, courseID: String, commentID: String, threadID: String) {
        let discussionCommentController = DiscussionCommentsViewController(environment: environment, courseID: courseID, commentID: commentID, threadID: threadID)
        if let delegate = controller as? DiscussionCommentsViewControllerDelegate {
            discussionCommentController.delegate = delegate
        }
        
        controller.navigationController?.pushViewController(discussionCommentController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(controller: UIViewController, courseID : String, response : DiscussionComment, closed : Bool, thread: DiscussionThread, isDiscussionBlackedOut: Bool) {
        let commentsVC = DiscussionCommentsViewController(environment: environment, courseID : courseID, responseItem: response, closed: closed, thread: thread, isDiscussionBlackedOut: isDiscussionBlackedOut)
        
        if let delegate = controller as? DiscussionCommentsViewControllerDelegate {
            commentsVC.delegate = delegate
        }
        
        controller.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(controller: UIViewController, courseID : String, thread:DiscussionThread, context: DiscussionNewCommentViewController.Context) {
        let newCommentViewController = DiscussionNewCommentViewController(environment: environment, courseID : courseID, thread:thread,  context: context)
        
        if let delegate = controller as? DiscussionNewCommentViewControllerDelegate {
            newCommentViewController.delegate = delegate
        }

    controller.present(ForwardingNavigationController(rootViewController: newCommentViewController), animated: true, completion: nil)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, topic: DiscussionTopic) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, topic: topic)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }

    func showDiscussionPosts(from controller: UIViewController, courseID: String, topicID: String) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, topicID: topicID)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showAllPostsFromController(controller : UIViewController, courseID : String, followedOnly following : Bool) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, following : following)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, queryString : String) {
        let postsController = PostsViewController(environment: environment, courseID: courseID, queryString : queryString)
        
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showDiscussionTopicsFromController(controller: UIViewController, courseID : String) {
        let topicsController = DiscussionTopicsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(topicsController, animated: true)
    }

    func showDiscussionNewPostFromController(controller: UIViewController, courseID : String, selectedTopic : DiscussionTopic?) {
        let newPostController = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic: selectedTopic)
        if let delegate = controller as? DiscussionNewPostViewControllerDelegate {
            newPostController.delegate = delegate
        }
        
        controller.present(ForwardingNavigationController(rootViewController: newPostController), animated: true, completion: nil)
    }
    
    func showHandoutsFromController(controller : UIViewController, courseID : String) {
        let handoutsViewController = CourseHandoutsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(handoutsViewController, animated: true)
    }
    
    func showProfile(controller: UIViewController? = nil, completion: ((_ success: Bool) -> ())? = nil) {
        let profileViewController = ProfileOptionsViewController(environment: environment)
        let navigationController = ForwardingNavigationController(rootViewController: profileViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        controller?.navigationController?.present(navigationController, animated: true) {
            completion?(true)
        }
    }
    
    func showValuePropDetailView(from controller: UIViewController? = nil, screen: CourseUpgradeScreen, course: OEXCourse, blockID: CourseBlockID? = nil, completion: (() -> Void)? = nil) {
        let upgradeDetailController = ValuePropDetailViewController(screen: screen, course: course, blockID: blockID, environment: environment)
        controller?.present(ForwardingNavigationController(rootViewController: upgradeDetailController), animated: true, completion: completion)
    }
    
    func showBrowserViewController(from controller: UIViewController, title: String?,  url: URL, completion: (() -> Void)? = nil) {
        let browserViewController = BrowserViewController(title: title, url: url, environment: environment)
        if let controller = controller as? BrowserViewControllerDelegate {
            browserViewController.delegate = controller
        }
        let navController = ForwardingNavigationController(rootViewController: browserViewController)
        navController.modalPresentationStyle = .fullScreen
        controller.present(navController, animated: true, completion: completion)
    }
    
    func showBannerViewController(from controller: UIViewController, url: URL, title: String?, delegate: BannerViewControllerDelegate? = nil, modal: Bool = true, showNavbar: Bool = false) {
        let bannerController = BannerViewController(url: url, title: title, environment: environment, showNavbar: showNavbar)
        bannerController.delegate = delegate
        if modal {
            let navController = ForwardingNavigationController(rootViewController: bannerController)
            navController.modalPresentationStyle = .fullScreen
            controller.present(navController, animated: true, completion: nil)
        }
        else {
            controller.navigationController?.pushViewController(bannerController, animated: true)
        }
    }
    
    func showProfileForUsername(controller: UIViewController? = nil, username : String, editable: Bool = true, modal: Bool = false) {
        OEXAnalytics.shared().trackProfileViewed(username: username)
        let editable = self.environment.session.currentUser?.username == username
        let profileController = UserProfileViewController(environment: environment, username: username, editable: editable)
        if modal {
            controller?.present(ForwardingNavigationController(rootViewController: profileController), animated: true, completion: nil)
        }
        else {
            if let controller = controller {
                controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                controller.navigationController?.pushViewController(profileController, animated: true)
            } else {
                showContentStack(withRootController: profileController, animated: true)
            }
        }
    }
    
    func showProfileEditorFromController(controller : UIViewController) {
        guard let profile = environment.dataManager.userProfileManager.feedForCurrentUser().output.value else {
            return
        }
        let editController = UserProfileEditViewController(profile: profile, environment: environment)
        controller.navigationController?.pushViewController(editController, animated: true)
    }
    
    func showDownloadVideoQuality(from controller: UIViewController, delegate: VideoDownloadQualityDelegate?, modal: Bool = false) {
        let videoQualityController = VideoDownloadQualityViewController.init(environment: environment, delegate: delegate)
        if modal {
            controller.present(ForwardingNavigationController(rootViewController: videoQualityController), animated: true, completion: nil)
        } else {
            controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            controller.navigationController?.pushViewController(videoQualityController, animated: true)
        }
    }
    
    func showCertificate(url: NSURL, title: String?, fromController controller: UIViewController) {
        let c = CertificateViewController(environment: environment)
        c.title = title
        controller.navigationController?.pushViewController(c, animated: true)
        c.loadRequest(request: URLRequest(url: url as URL) as NSURLRequest)
    }
    
    func showCourseWithID(courseID: String, fromController: UIViewController, animated: Bool = true, completion: ((UIViewController) -> Void)? = nil) {
        let controller = CourseDashboardViewController(environment: environment, courseID: courseID)
        controller.hidesBottomBarWhenPushed = true
        fromController.navigationController?.pushViewController(controller, animated: animated, completion: completion)
    }
    
    func showCourseCatalog(fromController: UIViewController? = nil, bottomBar: UIView? = nil, searchQuery: String? = nil) {
        guard let controller = discoveryViewController(bottomBar: bottomBar, searchQuery: searchQuery) else { return }
        if let fromController = fromController {
            fromController.tabBarController?.selectedIndex = EnrolledTabBarViewController.courseCatalogIndex
        } else {
            showControllerFromStartupScreen(controller: controller)
        }
        self.environment.analytics.trackUserFindsCourses()
    }
    
    func discoveryViewController(bottomBar: UIView? = nil, searchQuery: String? = nil) -> UIViewController? {
        guard environment.config.discovery.isEnabled else { return nil }

        return environment.config.discovery.type == .webview ? OEXFindCoursesViewController(environment: environment, showBottomBar: true, bottomBar: bottomBar, searchQuery: searchQuery) : CourseCatalogViewController(environment: environment)
    }
    
    func showProgramDetail(from controller: UIViewController, with pathId: String, bottomBar: UIView?) {
        let programDetailViewController = ProgramsDiscoveryViewController(with: environment, pathId: pathId, bottomBar: bottomBar?.copy() as? UIView)
        pushViewController(controller: programDetailViewController, fromController: controller)
    }

    private func showControllerFromStartupScreen(controller: UIViewController) {
        let backButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        backButton.oex_setAction({
            controller.dismiss(animated: true, completion: nil)
        })
        controller.navigationItem.leftBarButtonItem = backButton
        let navController = ForwardingNavigationController(rootViewController: controller)

        present(navController, from:nil, completion: nil)
    }

    func showCourseCatalogDetail(courseID: String, fromController: UIViewController) {
        let detailController = CourseCatalogDetailViewController(environment: environment, courseID: courseID)
        fromController.navigationController?.pushViewController(detailController, animated: true)
    }
    
    func showAppReviewIfNeeded(fromController: UIViewController) {
        if RatingViewController.canShowAppReview(environment: environment){
            let reviewController = RatingViewController(environment: environment)
            
            reviewController.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            reviewController.providesPresentationContextTransitionStyle = true
            reviewController.definesPresentationContext = true
            
            if let controller = fromController as? RatingViewControllerDelegate {
                reviewController.delegate = controller
            }
            
            fromController.present(reviewController, animated: false, completion: nil)
        }
    }
    
    func showWhatsNew(fromController controller : UIViewController) {
        let whatsNewController = WhatsNewViewController(environment: environment)
        let navController = ForwardingNavigationController(rootViewController: whatsNewController)
        navController.setNavigationBarHidden(true, animated: false)
        controller.present(navController, animated: true, completion: nil)
    }

    // MARK: - LOGIN / LOGOUT

    @objc func showSplash() {
        removeCurrentContentController()

        let splashController: UIViewController
        
        if !environment.config.isRegistrationEnabled {
            splashController = loginViewController()
        }
        else if environment.config.newLogistrationFlowEnabled {
            splashController = StartupViewController(environment: environment)
        } else {
            splashController = OEXLoginSplashViewController(environment: environment)
        }
        
        makeContentControllerCurrent(splashController)
    }

    func pushViewController(controller: UIViewController, fromController: UIViewController) {
        fromController.navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc public func logout() {
        invalidateToken()
        environment.session.closeAndClear()
        environment.session.removeAllWebData()
        showLoggedOutScreen()
    }
    
    func invalidateToken() {
        if let refreshToken = environment.session.token?.refreshToken, let clientID = environment.config.oauthClientID() {
            let networkRequest = LogoutApi.invalidateToken(refreshToken: refreshToken, clientID: clientID)
            environment.networkManager.taskForRequest(networkRequest) { _ in }
        }
        environment.networkManager.tokenStatus = .prelogin
    }

    // MARK: - Debug
    func showDebugPane() {
        let debugMenu = DebugMenuViewController(environment: environment)
        showContentStack(withRootController: debugMenu, animated: true)
    }
    
    public func showProgramDetails(with url: URL, from controller: UIViewController) {
        let programDetailsController = ProgramsViewController(environment: environment, programsURL: url, viewType: .detail)
        programDetailsController.hidesBottomBarWhenPushed = true
        controller.navigationController?.pushViewController(programDetailsController, animated: true)
    }
    
    @objc public func showCourseDetails(from controller: UIViewController, with coursePathID: String, bottomBar: UIView?) {
        let courseInfoViewController = OEXCourseInfoViewController(environment: environment, pathID: coursePathID, bottomBar: bottomBar?.copy() as? UIView)
        controller.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        controller.navigationController?.pushViewController(courseInfoViewController, animated: true)
    }
}

extension OEXRouter: UINavigationControllerDelegate {
    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        viewController.navigationController?.completionHandler()
    }
}

extension UIViewController {
    func find<T: UIViewController>(viewController: T.Type) -> T? {
        var currentViewController = self
        while let parentViewController = currentViewController.parent {
            if let result = parentViewController as? T {
                return result
            }
            currentViewController = parentViewController
        }
        return nil
    }
}
