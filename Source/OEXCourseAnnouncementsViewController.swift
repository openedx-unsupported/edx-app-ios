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
        let urlAddress = NSURL(string: "Http://www.google.com")
        var request = NSURLRequest(URL: urlAddress!)
        self.webView.loadRequest(request)
        
        
//        loadAnnouncementsData()
        // Do any additional setup after loading the view.
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
            if(successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS)
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
            
//            html += announ
        }
    }
    
    
//    - (void)useAnnouncements:(NSArray*)announcements {
//    if(announcements.count < 1) {
//    return;
//    }
//    self.announcementsNotAvailableLabel.hidden = YES;
//    NSMutableString* html = [[NSMutableString alloc] init];
//    [announcements enumerateObjectsUsingBlock:^(OEXAnnouncement* announcement, NSUInteger idx, BOOL* stop) {
//    [html appendFormat:@"<div class=\"announcement-header\">%@</div>", announcement.heading];
//    [html appendString:@"<hr class=\"announcement\"/>"];
    
//    [html appendString:announcement.content];
//    if(idx + 1 < announcements.count) {
//    [html appendString:@"<div class=\"announcement-separator\"/></div>"];
//    }
//    }];
//    NSString* displayHTML = [self.environment.styles styleHTMLContent:html];
//    [self.announcementsWebView loadHTMLString:displayHTML baseURL:[NSURL URLWithString:self.environment.config.apiHostURL]];
//    
//    self.announcementsWebView.hidden = YES;
//    if(self.webActivityIndicator) {
//    [self.webActivityIndicator removeFromSuperview];
//    }
//    if(!self.webActivityIndicator) {
//    self.webActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
//    }
//    [self.scrollView addSubview:self.webActivityIndicator];
//    self.webActivityIndicator.frame = self.announcementsWebView.frame;
//    [self.webActivityIndicator startAnimating];
//    }
    
    
    
    
    
    
    
    
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
