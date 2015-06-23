//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let notificationLabelLeadingOffset = 20.0
private let notificationLabelTrailingOffset = -10.0
private let notificationBarHeight = 50.0

class CourseAnnouncementsViewControllerEnvironment : NSObject {
    let config : OEXConfig?
    let dataInterface : OEXInterface
    weak var router : OEXRouter?
    let styles : OEXStyles
    let pushSettingsManager : OEXPushSettingsManager
    
    init(config : OEXConfig?, dataInterface : OEXInterface, router : OEXRouter, styles : OEXStyles, pushSettingsManager : OEXPushSettingsManager) {
        self.config = config
        self.dataInterface = dataInterface
        self.router = router
        self.styles = styles
        self.pushSettingsManager = pushSettingsManager
    }
}

class CourseAnnouncementsViewController: UIViewController {
    let environment: CourseAnnouncementsViewControllerEnvironment
    let course: OEXCourse
    var announcements: [OEXAnnouncement]
    let webView:UIWebView!
    let notificationBar : UIView!
    let notificationLabel : UILabel!
    let notificationSwitch : UISwitch!
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0, color: OEXStyles.sharedStyles().neutralBlack())
    let switchStyle = OEXStyles.sharedStyles().standardSwitchStyle()
    
    init(environment: CourseAnnouncementsViewControllerEnvironment, course: OEXCourse) {
        self.course = course
        self.announcements = [OEXAnnouncement]()
        self.environment = environment
        self.webView = UIWebView()
        self.notificationBar = UIView(frame: CGRectZero)
        self.notificationLabel = UILabel(frame: CGRectZero)
        self.notificationSwitch = UISwitch(frame: CGRectZero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setConstraints()
        setStyles()
        
        weak var weakSelf = self
        notificationSwitch.oex_addAction({ (sender : AnyObject!) -> Void in
            if let unwrappedSelf = weakSelf {
                unwrappedSelf.environment.pushSettingsManager.setPushDisabled(!unwrappedSelf.notificationSwitch.on, forCourseID: unwrappedSelf.course.course_id)
            }
        }, forEvents: UIControlEvents.ValueChanged)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: NOTIFICATION_URL_RESPONSE) { (notification, observer, _) -> Void in
            observer.handleDataNotification(notification)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAnnouncementsData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //MARK: - Setup UI
    func addSubviews() {
        self.view.addSubview(webView)
        self.view.addSubview(notificationBar)
        notificationBar.addSubview(notificationLabel)
        notificationBar.addSubview(notificationSwitch)
    }
    
    func setConstraints() {
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
            make.bottom.equalTo(webView.snp_top)
            make.height.equalTo(notificationBarHeight)
        }
        
        webView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
    }
    
    func setStyles() {
        notificationBar.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        switchStyle.applyToSwitch(notificationSwitch)
        fontStyle.applyToLabel(notificationLabel)
        notificationLabel.text = OEXLocalizedString("NOTIFICATIONS_ENABLED", nil)
        notificationSwitch.on = !self.environment.pushSettingsManager.isPushDisabledForCourseWithID(self.course.course_id)
    }
    
    //MARK: - Datasource
    func loadAnnouncementsData()
    {
        let dataParser = OEXDataParser()
        if let data = self.environment.dataInterface.resourceDataForURLString(self.course.course_updates, downloadIfNotAvailable: false)
        {
            self.announcements = dataParser.announcementsWithData(data) as! [OEXAnnouncement]
            useAnnouncements(announcementsToDisplay: self.announcements)
            //TODO: Hide the no announcements label
        }
        else{
            self.environment.dataInterface.downloadWithRequestString(self.course.course_updates, forceUpdate: true)
        }
    }
    
    func handleDataNotification(notification:NSNotification) {
        if let userinfo = notification.userInfo{
            let successString = userinfo[NOTIFICATION_KEY_STATUS] as! String
            let urlString = userinfo[NOTIFICATION_KEY_URL] as! String
            if(successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && urlString == self.course.course_updates)
            {
                loadAnnouncementsData()
            }
        
        }
    }
    
    //MARK: - Presenter
    
    func useAnnouncements(announcementsToDisplay announcements:NSArray)
    {
        if (announcements.count < 1)
        {
            return
        }
        
        //TODO: Hide the loader
        var html:String = String()
        
        for (index,announcement) in enumerate(announcements)
        {
                html += "<div class=\"announcement-header\">\(announcement.heading!)</div>"
                html += "<hr class=\"announcement\"/>"
                html += announcement.content
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
        }
        var displayHTML = self.environment.styles.styleHTMLContent(html)
        let baseURL = self.environment.config?.apiHostURL().flatMap { NSURL(string: $0 ) }
        self.webView?.loadHTMLString(displayHTML, baseURL: baseURL)
    }
}
