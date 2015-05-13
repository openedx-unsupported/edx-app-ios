//
//  OEXCourseDashboardViewController.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class OEXCourseDashboardViewControllerEnvironment : NSObject {
    weak var config: OEXConfig?
    weak var router: OEXRouter?
    
    init(config: OEXConfig, router: OEXRouter) {
        self.config = config
        self.router = router
    }
}


class OEXCourseDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var environment: OEXCourseDashboardViewControllerEnvironment
    private var course: OEXCourse
    
    var tableView: UITableView = UITableView()
    
    var iconsArray = NSArray()
    var titlesArray = NSArray()
    var detailsArray = NSArray()
    
    
    init(environment: OEXCourseDashboardViewControllerEnvironment, course: OEXCourse) {
        self.environment = environment
        self.course = course
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        tableView.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.view).offset(0)
            make.right.equalTo(self.view).offset(0)
            make.top.equalTo(self.view).offset(0)
            make.bottom.equalTo(self.view).offset(0)
        }
        
        // Register tableViewCell
        tableView.registerClass(OEXCourseDashboardCourseInfoCell.self, forCellReuseIdentifier: OEXCourseDashboardCourseInfoCell.identifier)
        tableView.registerClass(OEXCourseDashboardCell.self, forCellReuseIdentifier: OEXCourseDashboardCell.identifier)
        
        prepareTableViewData()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helpers
    
    // TODO: this is the temp data
    func prepareTableViewData() {
        
        if shouldEnableDiscussions() {
            self.titlesArray = ["Course", "Discussion", "Handouts", "Announcements"]
        }else {
            self.titlesArray = ["Course", "Handouts", "Announcements"]
        }
        
        if shouldEnableDiscussions() {
            self.detailsArray = ["Lectures, videos & homework, oh my!",
                "Lets talk about single-molecule diodes",
                "Virtual, so not really a handout",
                "It's 3 o'clock and all is well"]
        }else {
            self.detailsArray = ["Lectures, videos & homework, oh my!",
                "Virtual, so not really a handout",
                "It's 3 o'clock and all is well"]
        }
    }
    
    
    func shouldEnableDiscussions() -> Bool {
        return self.environment.config!.shouldEnableDiscussions()
    }
    

    // MARK: - TableView Data and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titlesArray.count + 1
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 200.0
        }else{
            return 80.0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(OEXCourseDashboardCourseInfoCell.identifier, forIndexPath: indexPath) as! OEXCourseDashboardCourseInfoCell
            
            cell.titleLabel.text = self.course.name
            cell.detailLabel.text = self.course.org + " | " + self.course.number
            
            //TODO: the way to load image is not perfect, need to do refactoring later
            cell.course = self.course
            cell.setCoverImage()
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier(OEXCourseDashboardCell.identifier, forIndexPath: indexPath) as! OEXCourseDashboardCell
            
            cell.titleLabel.text = self.titlesArray.objectAtIndex(indexPath.row - 1) as? String
            cell.detailLabel.text = self.detailsArray.objectAtIndex(indexPath.row - 1) as? String
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.row == 1 {
            showCourseware()
        }else if indexPath.row == self.titlesArray.count {
            showAnnouncements()
        }else if indexPath.row == self.titlesArray.count - 1 {
            showHandouts()
        }else{
            showDiscussions()
        }
        
    }
    
    func showCourseware() {
        self.environment.router?.showCoursewareForCourseWithID(self.course.course_id, fromController: self)
    }
    
    func showDiscussions() {
        self.environment.router?.showDiscussionTopicsForCourse(self.course, fromController: self)
    }
    
    func showHandouts() {
        // TODO
    }
    
    func showAnnouncements() {
        // TODO
    }
    
    
    
}
