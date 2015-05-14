//
//  CourseDashboardViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class CourseDashboardViewControllerEnvironment : NSObject {
    let config: OEXConfig?
    weak var router: OEXRouter?
    
    init(config: OEXConfig, router: OEXRouter) {
        self.config = config
        self.router = router
    }
}

class CourseDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    let environment: CourseDashboardViewControllerEnvironment!
    var course: OEXCourse!
    
    var tableView: UITableView = UITableView()
    
    var iconsArray = NSArray()
    var titlesArray = NSArray()
    var detailsArray = NSArray()
    
    init(environment: CourseDashboardViewControllerEnvironment, course: OEXCourse) {
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
        tableView.registerClass(CourseDashboardCourseInfoCell.self, forCellReuseIdentifier: CourseDashboardCourseInfoCell.identifier)
        tableView.registerClass(CourseDashboardCell.self, forCellReuseIdentifier: CourseDashboardCell.identifier)
        
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
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseDashboardCourseInfoCell.identifier, forIndexPath: indexPath) as! CourseDashboardCourseInfoCell
            
            cell.titleLabel.text = self.course.name
            cell.detailLabel.text = self.course.org + " | " + self.course.number
            
            //TODO: the way to load image is not perfect, need to do refactoring later
            cell.course = self.course
            cell.setCoverImage()
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseDashboardCell.identifier, forIndexPath: indexPath) as! CourseDashboardCell
            
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

extension CourseDashboardViewController { //Testing
    
    func t_canVisitDiscussions() -> Bool {
        //TODO: need to add test code for CourseDashboardViewController
        return true
    }
    
}

