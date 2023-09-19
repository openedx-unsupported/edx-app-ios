//
//  HTMLBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class HTMLBlockViewController: UIViewController, CourseBlockViewController, PreloadableBlockController, ScrollableDelegateProvider {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider
    
    public let courseID: String
    public let blockID: CourseBlockID?
    
    var block: CourseBlock? {
        return courseQuerier.blockWithID(id: blockID).firstSuccess().value
    }
    
    private let environment: Environment
    private let subkind: CourseHTMLBlockSubkind
    
    private lazy var courseDateBannerViewContainer = UIView()
    private let webController: AuthenticatedWebViewController
    
    private let loader = BackedStream<CourseBlock>()
    private let courseDateBannerLoader = BackedStream<(CourseDateBannerModel)>()
    private let courseQuerier: CourseOutlineQuerier

    private lazy var openInBrowserView = OpenInExternalBrowserView(frame: .zero)
    
    weak var scrollableDelegate: ScrollableDelegate?
    private var scrollByDragging = false
    
    public init(blockID: CourseBlockID?, courseID: String, environment: Environment, subkind: CourseHTMLBlockSubkind) {
        self.courseID = courseID
        self.blockID = blockID
        self.subkind = subkind
        self.environment = environment
        
        webController = AuthenticatedWebViewController(environment: environment, shouldListenForAjaxCallbacks: true)
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        super.init(nibName : nil, bundle : nil)

        webController.delegate = self
        webController.ajaxCallbackDelegate = self
        webController.scrollView.delegate = self
        
        addObserver()
        setupViews()
        loadWebviewStream()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_SHIFT_COURSE_DATES) { _, observer, _ in
            observer.hideCourseBannerView()
            observer.webController.reload()
        }
    }

    private func setupViews() {
        view.addSubview(courseDateBannerViewContainer)
        courseDateBannerViewContainer.snp.makeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.top.equalTo(view)
            make.height.equalTo(0)
        }
        
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)

        configureViews()
    }

    private func configureViews(containsiFrame: Bool = false) {

        if subkind == .Base, !containsiFrame {
            webController.view.snp.remakeConstraints { make in
                make.trailing.equalTo(view)
                make.leading.equalTo(view)
                make.top.equalTo(courseDateBannerViewContainer.snp.bottom)
                make.bottom.equalTo(view)
            }
        }
        else {
            if view.subviews.contains(openInBrowserView) {
                openInBrowserView.removeFromSuperview()
                openInBrowserView.delegate = nil
            }
            view.addSubview(openInBrowserView)
            openInBrowserView.delegate = self

            webController.view.snp.remakeConstraints { make in
                make.trailing.equalTo(view)
                make.leading.equalTo(view)
                make.top.equalTo(courseDateBannerViewContainer.snp.bottom)
            }

            openInBrowserView.snp.remakeConstraints { make in
                make.leading.equalTo(safeLeading)
                make.trailing.equalTo(safeTrailing)
                make.top.equalTo(webController.view.snp.bottom)
                make.height.equalTo(55)
                make.bottom.equalTo(safeBottom)
            }

            trackOpenInBrowserBannerEvent(displayName: AnalyticsDisplayName.OpenInBrowserBannerDisplayed, eventName: AnalyticsEventName.OpenInBrowserBannerDisplayed)
        }
    }
    
    private func loadWebviewStream(_ forceLoad: Bool = false) {
        if !loader.hasBacking || forceLoad {
            let courseQuerierStream = courseQuerier.blockWithID(id: self.blockID).firstSuccess()
            loader.addBackingStream(courseQuerierStream)
            
            courseQuerierStream.listen((self), success: { [weak self] block in
                if let url = block.blockURL {
                    let request = NSURLRequest(url: url as URL)
                    self?.webController.loadRequest(request: request)
                }
                else {
                    self?.webController.showError(error: nil)
                }
            }, failure: { [weak self] error in
                self?.webController.showError(error: error)
            })
        }
    }
    
    private func loadBannerStream() {
        guard subkind == .Problem,
              let isSelfPaced = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course.isSelfPaced,
              isSelfPaced else { return }
        
        let courseBannerRequest = CourseDateBannerAPI.courseDateBannerRequest(courseID: courseID)
        let courseBannerStream = environment.networkManager.streamForRequest(courseBannerRequest)
        courseDateBannerLoader.addBackingStream(courseBannerStream)
        
        courseBannerStream.listen((self), success: { [weak self] courseBannerModel in
            self?.loadCourseDateBannerView(bannerModel: courseBannerModel)
        }, failure: { _ in
            
        })
    }
    
    private func loadCourseDateBannerView(bannerModel: CourseDateBannerModel) {
        var height: CGFloat = 0
        if bannerModel.hasEnded {
            height = 0
        } else {
            guard let status = bannerModel.bannerInfo.status else { return }
            
            var courseDateBannerView: BannerView
            
            if environment.config.isNewComponentNavigationEnabled {
                courseDateBannerView = NewCourseDateBannerView()
            } else {
                courseDateBannerView = CourseDateBannerView()
            }
            
            if let courseDateBannerView = courseDateBannerView as? UIView {
                courseDateBannerViewContainer.addSubview(courseDateBannerView)
                courseDateBannerView.snp.remakeConstraints { make in
                    make.edges.equalTo(courseDateBannerViewContainer)
                }
            }
            
            if status == .resetDatesBanner {
                courseDateBannerView.delegate = self
                courseDateBannerView.bannerInfo = bannerModel.bannerInfo
                courseDateBannerView.setupView()
                height = StandardVerticalMargin * 16
                trackDateBannerAppearanceEvent(bannerModel: bannerModel)
            }
        }
        
        courseDateBannerViewContainer.snp.remakeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.top.equalTo(view)
            make.height.equalTo(height)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func hideCourseBannerView() {
        courseDateBannerViewContainer.snp.remakeConstraints { make in
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.top.equalTo(view)
            make.height.equalTo(0)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    public func preloadData() {
        loadWebviewStream()
    }
    
    private func resetCourseDate() {
        trackDatesShiftTapped()
        
        let request = CourseDateBannerAPI.courseDatesResetRequest(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] result in
            if let _ = result.error {
                self?.trackDatesShiftEvent(success: false)
                self?.showDateResetSnackBar(message: Strings.Coursedates.ResetDate.errorMessage)
            } else {
                self?.trackDatesShiftEvent(success: true)
                self?.showSnackBar()
                self?.postCourseDateResetNotification()
            }
        }
    }
    
    private func trackDateBannerAppearanceEvent(bannerModel: CourseDateBannerModel) {
        guard let eventName = bannerModel.bannerInfo.status?.analyticsEventName,
           let bannerType = bannerModel.bannerInfo.status?.analyticsBannerType,
           let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesBannerAppearence(screenName: AnalyticsScreenName.AssignmentScreen, courseMode: courseMode, eventName: eventName, bannerType: bannerType)
    }
    
    private func trackDatesShiftTapped() {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftButtonTapped(screenName: AnalyticsScreenName.AssignmentScreen, courseMode: courseMode)
    }
    
    private func trackDatesShiftEvent(success: Bool) {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftEvent(screenName: AnalyticsScreenName.AssignmentScreen, courseMode: courseMode, success: success)
    }
    
    private func showSnackBar() {
        showDateResetSnackBar(message: Strings.Coursedates.toastSuccessMessage, buttonText: Strings.Coursedates.viewAllDates, showButton: true) { [weak self] in
            if let weakSelf = self {
                weakSelf.environment.router?.showDatesTabController(controller: weakSelf)
                weakSelf.hideSnackBar()
            }
        }
    }

    private func trackOpenInBrowserBannerEvent(displayName: AnalyticsDisplayName, eventName: AnalyticsEventName) {
        let enrollment = environment.interface?.enrollmentForCourse(withID: courseID)?.type ?? .none
        
        environment.analytics.trackOpenInBrowserBannerEvent(displayName: displayName, eventName: eventName, userType: enrollment.rawValue, courseID: courseID, componentID: blockID ?? "", componentType: block?.typeName ?? "", openURL: block?.webURL?.absoluteString ?? "")
    }
    
    private func postCourseDateResetNotification() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_SHIFT_COURSE_DATES)))
    }
    
    private func markBlockAsComplete() {
        if let block = block {
            if !block.isCompleted {
                block.isCompleted = true
            }
        }
    }
    
    deinit {
        webController.removeCallbackHandler()
        NotificationCenter.default.removeObserver(self)
    }
}

extension HTMLBlockViewController: AuthenticatedWebViewControllerDelegate {
    func authenticatedWebViewController(authenticatedController: AuthenticatedWebViewController, didFinishLoading webview: WKWebView) {
        authenticatedController.setLoadControllerState(withState: .Loaded)
        loadBannerStream()
        elavuateHTMLForiFrame(with: webview)
    }

    func elavuateHTMLForiFrame(with webview: WKWebView) {
        if subkind == .Base {
            // The type of HTML basic component and one created with iframe tool is same which is HTML
            // To find out either the HTML block is created with iframe tool or not we need to look into the HTML
            let javascript = "try { var top_div_list = document.querySelectorAll('div[data-usage-id=\"\(blockID ?? "")\"]'); top_div_list.length == 1 && top_div_list[0].querySelectorAll(\"iframe\").length > 0; } catch { false; };"

            webview.evaluateJavaScript(javascript) { [weak self] (containsiframe: Any?, error: Error?) in
                if let containsiframe = containsiframe as? Bool, containsiframe {
                    self?.configureViews(containsiFrame: true)
                }
            }
        }
    }
}

extension HTMLBlockViewController: CourseShiftDatesDelegate {
    func courseShiftDateButtonAction() {
        resetCourseDate()
    }
}

extension HTMLBlockViewController: AJAXCompletionCallbackDelegate {
    func didCompletionCalled(completion: Bool) {
        markBlockAsComplete()
    }
}

extension HTMLBlockViewController: OpenInExternalBrowserViewDelegate, BrowserViewControllerDelegate {
    func openInExternalBrower() {
        guard let blockID = block?.blockID,
              let parent = courseQuerier.parentOfBlockWith(id: blockID).firstSuccess().value,
              let unitURL = parent.blockURL as URL? else { return }

        trackOpenInBrowserBannerEvent(displayName: AnalyticsDisplayName.OpenInBrowserBannerTapped, eventName: AnalyticsEventName.OpenInBrowserBannerTapped)
        environment.router?.showBrowserViewController(from: self, title: parent.displayName, url: unitURL)
    }

    // We want to force reload the component screen because if the learner has taken any action
    // on the in-app browser screen, the learner get updated experience on the component as well
    func didDismissBrowser() {
        loadWebviewStream(true)
    }
}

extension HTMLBlockViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollByDragging = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollByDragging {
            scrollableDelegate?.scrollViewDidScroll(scrollView: scrollView)
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollByDragging = false
    }
}
