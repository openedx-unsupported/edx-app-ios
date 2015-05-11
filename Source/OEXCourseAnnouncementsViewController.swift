//
//  OEXCourseAnnouncementsViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 07/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class OEXCourseAnnouncementsViewControllerEnvironment : NSObject {
    weak var router : OEXRouter?
    var styles : OEXStyles?
    var config : OEXConfig?
    init(router : OEXRouter, styles : OEXStyles, config : OEXConfig) {
        self.router = router
        self.styles = styles
        self.config = config
    }
}


class OEXCourseAnnouncementsViewController: UIViewController {

    let dataInterface: OEXInterface
    let dataParser: OEXDataParser
    let environment: OEXCourseAnnouncementsViewControllerEnvironment
    let course: OEXCourse
    var announcements: NSArray
    let webView:UIWebView!
    
    
    init(environment: OEXCourseAnnouncementsViewControllerEnvironment, course: OEXCourse) {
        self.course = course
        self.dataInterface = OEXInterface()
        self.dataParser = OEXDataParser()
        self.announcements = NSArray()
        self.environment = environment
        self.webView = UIWebView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        drawUI()
        loadAnnouncementsData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func drawUI(){
        //setup Webview
        self.view.addSubview(webView)
        webView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    
    
    //MARK: - Datasource
    
    
    func loadAnnouncementsData()
    {
        let data = self.dataInterface.resourceDataForURLString(self.course.course_updates, downloadIfNotAvailable: false)
        if( (data != nil))
        {
            self.announcements = self.dataParser.announcementsWithData(data)
            useAnnouncements(announcementsToDisplay: self.announcements)
            //TODO: Hide the no announcements label
        }
        else{
            self.dataInterface.downloadWithRequestString(self.course.course_updates, forceUpdate: true)
        }
    }
    
    
    func dataAvailable(notification:NSNotification) {
        if var userinfo = notification.userInfo{
            let successString: String = userinfo[NOTIFICATION_KEY_STATUS] as! String
            let urlString: String = userinfo[NOTIFICATION_KEY_URL] as! String
            if(successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && urlString == self.course.course_updates)
            {
                loadAnnouncementsData()
            }
        
        }
        else
        {
            return
        }
        
        
    }
    
    //MARK: - Observers
    
    func addObservers()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dataAvailable:"), name: NOTIFICATION_URL_RESPONSE, object: nil)
    }
    
    func removeObservers()
    {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NOTIFICATION_URL_RESPONSE, object: nil)
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
            if let ann = announcement as? OEXAnnouncement
            {
                html += "<div class=\"announcement-header\">\(ann.heading!)</div>"
                html += "<hr class=\"announcement\"/>"
                html += ann.content
                if(index + 1 < announcements.count)
                {
                    html += "<div class=\"announcement-separator\"/></div>"
                }
                var displayHTML = self.environment.styles?.styleHTMLContent(html)
                self.webView?.loadHTMLString(displayHTML, baseURL: NSURL(string: self.environment.config!.apiHostURL()))
            }
        }
    }
}
