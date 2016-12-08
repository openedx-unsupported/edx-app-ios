//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import edXCore

private let notificationLabelLeadingOffset = 20.0
private let notificationLabelTrailingOffset = -10.0
private let notificationBarHeight = 50.0

@objc protocol CourseAnnouncementsViewControllerEnvironment : OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXAnalyticsProvider {}

extension RouterEnvironment : CourseAnnouncementsViewControllerEnvironment {}


private func announcementsDeserializer(response: NSHTTPURLResponse, json: JSON) -> Result<[OEXAnnouncement]> {
    return json.array.toResult().map {
        return $0.map {
            return OEXAnnouncement(dictionary: $0.dictionaryObject ?? [:])
        }
    }
}


class CourseAnnouncementsViewController: OfflineSupportViewController, UIWebViewDelegate {
    private let environment: CourseAnnouncementsViewControllerEnvironment
    
    let courseID: String
    
    private let loadController = LoadStateViewController()
    private let announcementsLoader = BackedStream<[OEXAnnouncement]>()
    
    private let webView: UIWebView
    private let notificationBar : UIView
    private let notificationLabel : UILabel
    private let notificationSwitch : UISwitch
    
    private let fontStyle = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlack())
    private let switchStyle = OEXStyles.sharedStyles().standardSwitchStyle()
    
    init(environment: CourseAnnouncementsViewControllerEnvironment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        self.webView = UIWebView()
        self.notificationBar = UIView(frame: CGRectZero)
        self.notificationBar.clipsToBounds = true
        self.notificationLabel = UILabel(frame: CGRectZero)
        self.notificationSwitch = UISwitch(frame: CGRectZero)
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
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        webView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        webView.opaque = false
        
        loadController.setupInController(self, contentView: self.webView)
        
        notificationSwitch.oex_addAction({[weak self] _ in
            if let owner = self {
                owner.environment.dataManager.pushSettings.setPushDisabled(!owner.notificationSwitch.on, forCourseID: owner.courseID)
            }}, forEvents: UIControlEvents.ValueChanged)
        
        self.webView.delegate = self
        
        announcementsLoader.listen(self) {[weak self] in
            switch $0 {
            case let .Success(announcements):
                self?.useAnnouncements(announcements)
            case let .Failure(error):
                if !(self?.announcementsLoader.active ?? false) {
                    self?.loadController.state = LoadState.failed(error)
                }
            }
        }
    }
    
    private static func requestForCourse(course: OEXCourse) -> NetworkRequest<[OEXAnnouncement]> {
        let announcementsURL = course.course_updates ?? "".oex_formatWithParameters([:])
        return NetworkRequest(method: .GET,
            path: announcementsURL,
            requiresAuth: true,
            deserializer: .JSONResponse(announcementsDeserializer)
        )
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadContent()
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenAnnouncements, courseID: courseID, value: nil)
    }
    
    override func reloadViewData() {
        loadContent()
    }
    
    private func loadContent() {
        if !announcementsLoader.active {
            let networkManager = environment.networkManager
            announcementsLoader.backWithStream(
                environment.dataManager.enrollmentManager.streamForCourseWithID(courseID).transform {
                    let request = CourseAnnouncementsViewController.requestForCourse($0.course)
                    return networkManager.streamForRequest(request, persistResponse: true)
                }
            )
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
        notificationLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(notificationBar.snp_leading).offset(notificationLabelLeadingOffset)
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationSwitch)
        }
        
        notificationSwitch.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(notificationBar)
            make.trailing.equalTo(notificationBar).offset(notificationLabelTrailingOffset)
        }
        
        notificationBar.snp_makeConstraints { (make) -> Void in
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
        
        webView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(notificationBar.snp_bottom)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    private func setStyles() {
        self.navigationItem.title = Strings.courseAnnouncements
        notificationBar.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        switchStyle.applyToSwitch(notificationSwitch)
        notificationLabel.attributedText = fontStyle.attributedStringWithText(Strings.notificationsEnabled)
        notificationSwitch.on = !environment.dataManager.pushSettings.isPushDisabledForCourseWithID(courseID)
    }
    //MARK: - Presenter
    
    private func useAnnouncements(announcements: [OEXAnnouncement]) {
        guard announcements.count > 0 else {
            self.loadController.state = LoadState.empty(icon: nil, message: Strings.announcementUnavailable)
            return
        }
        
        var html:String = String()
        
        for (index,announcement) in announcements.enumerate() {
                html += "<div class=\"announcement-header\">\(announcement.heading)</div>"
                html += "<hr class=\"announcement\"/>"
                html += announcement.content ?? ""
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
        }
        let displayHTML = OEXStyles.sharedStyles().styleHTMLContent(html, stylesheet: "handouts-announcements") ?? ""
        let baseURL = self.environment.config.apiHostURL()
        self.webView.loadHTMLString(displayHTML, baseURL: baseURL)
    }
    
    //MARK: - UIWebViewDeleagte
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (navigationType != UIWebViewNavigationType.Other) {
            if let URL = request.URL {
                UIApplication.sharedApplication().openURL(URL)
                return false
            }
        }
        return true
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.loadController.state = .Loaded
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        self.loadController.state = LoadState.failed(error)
    }
}

// Testing only
extension CourseAnnouncementsViewController {
    var t_showingNotificationBar : Bool {
        return self.notificationBar.bounds.size.height > 0
    }
}
