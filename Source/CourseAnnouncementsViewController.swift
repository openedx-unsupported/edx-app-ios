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

private let notificationLabelLeadingOffset = 20.0
private let notificationLabelTrailingOffset = -10.0
private let notificationBarHeight = 50.0

private func announcementsDeserializer(response: HTTPURLResponse, json: JSON) -> Result<[OEXAnnouncement]> {
    return json.array.toResult().map {
        return $0.map {
            return OEXAnnouncement(dictionary: $0.dictionaryObject ?? [:])
        }
    }
}

class CourseAnnouncementsViewController: OfflineSupportViewController, LoadStateViewReloadSupport, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    @objc let courseID: String
    
    private let loadController = LoadStateViewController()
    private let announcementsLoader = BackedStream<[OEXAnnouncement]>()
    
    private let webView: WKWebView
    fileprivate let notificationBar : UIView
    private let notificationLabel : UILabel
    private let notificationSwitch : UISwitch
    private let environment: Environment
    private let fontStyle = OEXTextStyle(weight : .normal, size: .base, color: OEXStyles.shared().neutralBlack())
    private let switchStyle = OEXStyles.shared().standardSwitchStyle()
    
    @objc init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        self.webView = WKWebView()
        self.notificationBar = UIView(frame: CGRect.zero)
        self.notificationBar.clipsToBounds = true
        self.notificationLabel = UILabel(frame: CGRect.zero)
        self.notificationSwitch = UISwitch(frame: CGRect.zero)
        super.init(env: environment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
        setConstraints()
        setStyles()
        
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webView.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        webView.isOpaque = false
        
        loadController.setupInController(controller: self, contentView: self.webView)
        
        notificationSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
                owner.environment.dataManager.pushSettings.setPushDisabled(!owner.notificationSwitch.isOn, forCourseID: owner.courseID)
            }}, for: UIControl.Event.valueChanged)
        
        webView.navigationDelegate = self
        
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
        self.loadContent()
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
        self.view.addSubview(webView)
        self.view.addSubview(notificationBar)
        notificationBar.addSubview(notificationLabel)
        notificationBar.addSubview(notificationSwitch)
    }
    
    private func setConstraints() {
        notificationLabel.snp.makeConstraints { make in
            make.leading.equalTo(notificationBar.snp.leading).offset(notificationLabelLeadingOffset)
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationSwitch)
        }
        
        notificationSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationBar).offset(notificationLabelTrailingOffset)
        }
        
        notificationBar.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            if environment.config.pushNotificationsEnabled {
                make.height.equalTo(notificationBarHeight)
            }
            else {
                make.height.equalTo(0)
            }
        }
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(notificationBar.snp.bottom)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.bottom.equalTo(safeBottom)
        }
    }
    
    private func setStyles() {
        self.navigationItem.title = Strings.courseAnnouncements
        notificationBar.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        switchStyle.apply(to: notificationSwitch)
        notificationLabel.attributedText = fontStyle.attributedString(withText: Strings.notificationsEnabled)
        notificationSwitch.isOn = !environment.dataManager.pushSettings.isPushDisabledForCourse(withID: courseID)
    }
    //MARK: - Presenter
    
    private func useAnnouncements(announcements: [OEXAnnouncement]) {
        guard announcements.count > 0 else {
            self.loadController.state = LoadState.empty(icon: nil, message: Strings.announcementUnavailable)
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
        let baseURL = self.environment.config.apiHostURL()
        self.webView.loadHTMLString(displayHTML, baseURL: baseURL)
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
                UIApplication.shared.openURL(URL)
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

// Testing only
extension CourseAnnouncementsViewController {
    var t_showingNotificationBar : Bool {
        return self.notificationBar.bounds.size.height > 0
    }
}
