//
//  CourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseAnnouncementsViewControllerEnvironment : NSObject {
    let config : OEXConfig
    let dataInterface : OEXInterface
    weak var router : OEXRouter?
    let styles : OEXStyles
    
    init(config : OEXConfig, dataInterface : OEXInterface, router : OEXRouter, styles : OEXStyles) {
        self.config = config
        self.dataInterface = dataInterface
        self.router = router
        self.styles = styles
    }
}

class CourseAnnouncementsViewController: UIViewController {
    let environment: CourseAnnouncementsViewControllerEnvironment
    let course: OEXCourse
    var announcements: [OEXAnnouncement]
    let webView:UIWebView!
    
    
    init(environment: CourseAnnouncementsViewControllerEnvironment, course: OEXCourse) {
        self.course = course
        self.announcements = [OEXAnnouncement]()
        self.environment = environment
        self.webView = UIWebView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webView)
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().oex_addObserver(self, notification: NOTIFICATION_URL_RESPONSE) { (notification : NSNotification!, observer : AnyObject!, removeable : OEXRemovable!) -> Void in
            if let vc = observer as? CourseAnnouncementsViewController{
                vc.handleDataNotification(notification)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadAnnouncementsData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        self.webView?.loadHTMLString(displayHTML, baseURL: NSURL(string: self.environment.config.apiHostURL()))
    }
}
