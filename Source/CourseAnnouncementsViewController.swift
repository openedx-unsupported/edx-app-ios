//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import WebKit
import edXCore

private func announcementsDeserializer(response: HTTPURLResponse, json: JSON) -> Result<[OEXAnnouncement]> {
    return json.array.toResult().map {
        return $0.map {
            return OEXAnnouncement(dictionary: $0.dictionaryObject ?? [:])
        }
    }
}

class CourseAnnouncementsViewController: OfflineSupportViewController, LoadStateViewReloadSupport, InterfaceOrientationOverriding, ScrollableDelegateProvider {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    @objc let courseID: String
    
    private let loadController = LoadStateViewController()
    private let announcementsLoader = BackedStream<[OEXAnnouncement]>()
    
    private let webView: WKWebView
    private let environment: Environment
    private let fontStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared().neutralBlack())
    private let switchStyle = OEXStyles.shared().standardSwitchStyle()
    
    weak var scrollableDelegate: ScrollableDelegate?
    private var scrollByDragging = false
    
    @objc init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        self.webView = WKWebView(frame: .zero, configuration: environment.config.webViewConfiguration())
        super.init(env: environment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.courseAnnouncements

        addSubviews()
        setConstraints()
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        
        loadController.setupInController(controller: self, contentView: webView)
        announcementsLoader.listen(self) {[weak self] in
            switch $0 {
            case let Result.success(announcements):
                self?.useAnnouncements(announcements: announcements)
            case let Result.failure(error):
                if !(self?.announcementsLoader.active ?? false) {
                    self?.loadController.state = LoadState.failed(error: error)
                }
            }
        }

        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "CourseAnnouncementsViewController:view"
        webView.accessibilityIdentifier = "CourseAnnouncementsViewController:web-view"
    }
    
    private static func requestForCourse(course: OEXCourse) -> NetworkRequest<[OEXAnnouncement]> {
        let announcementsURL = course.course_updates ?? "".oex_format(withParameters: [:])
        return NetworkRequest(method: .GET,
            path: announcementsURL,
            requiresAuth: true,
            deserializer: .jsonResponse(announcementsDeserializer)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadContent()
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenAnnouncements, courseID: courseID, value: nil)
    }
    
    override func reloadViewData() {
        loadContent()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func loadContent() {        
        if !announcementsLoader.active {
            loadController.state = .Initial
            let courseStream = environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID)
            let announcementStream = courseStream.transform {[weak self] enrollment in
                return self?.environment.networkManager.streamForRequest(CourseAnnouncementsViewController.requestForCourse(course: enrollment.course), persistResponse: true) ?? OEXStream<Array>(error : NSError.oex_courseContentLoadError())
            }
            announcementsLoader.backWithStream((courseStream.value != nil) ? announcementStream : OEXStream<Array>(error : NSError.oex_courseContentLoadError()))
        }
    }
    
    //MARK: - Setup UI
    private func addSubviews() {
        view.addSubview(webView)
    }
    
    private func setConstraints() {
        webView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    //MARK: - Presenter
    
    private func useAnnouncements(announcements: [OEXAnnouncement]) {
        guard announcements.count > 0 else {
            loadController.state = LoadState.empty(icon: nil, message: Strings.announcementUnavailable)
            return
        }
        
        var html:String = String()
        
        for (index,announcement) in announcements.enumerated() {
                html += "<div class=\"announcement-header\">\(announcement.heading ?? "")</div>"
                html += "<hr class=\"announcement\"/>"
                html += announcement.content ?? ""
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
        }
        let displayHTML = OEXStyles.shared().styleHTMLContent(html, stylesheet: "handouts-announcements") ?? ""
        let baseURL = environment.config.apiHostURL()
        webView.loadHTMLString(displayHTML, baseURL: baseURL)
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        loadContent()
    }
}

extension CourseAnnouncementsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        switch navigationAction.navigationType {
        case .linkActivated, .formSubmitted, .formResubmitted:
            if let URL = navigationAction.request.url, UIApplication.shared.canOpenURL(URL){
                UIApplication.shared.open(URL, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        default:
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadController.state = .Loaded
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadController.state = LoadState.failed(error: error as NSError)
    }
}

extension CourseAnnouncementsViewController: UIScrollViewDelegate {
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
