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

struct DashboardItem {
    var title: String = ""
    var detail: String = ""
    var action:(() -> Void)!
}

class CourseDashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    let environment: CourseDashboardViewControllerEnvironment!
    var course: OEXCourse!
    
    private var tableView: UITableView = UITableView()
    private var selectedIndexPath: NSIndexPath?
    
    var cellItems: [DashboardItem] = []
    
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
        
        self.view.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        tableView.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        // Register tableViewCell
        tableView.registerClass(CourseDashboardCourseInfoCell.self, forCellReuseIdentifier: CourseDashboardCourseInfoCell.identifier)
        tableView.registerClass(CourseDashboardCell.self, forCellReuseIdentifier: CourseDashboardCell.identifier)
        
        prepareTableViewData()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedIndexPath {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        self.navigationController?.navigationBarHidden = false
    }
    
    // TODO: this is the temp data
    func prepareTableViewData() {
        var item = DashboardItem(title: OEXLocalizedString("COURSEDASHBOARD_COURSE", nil), detail: OEXLocalizedString("COURSEDASHBOARD_COURSE_DETAIL", nil)) {[weak self] () -> Void in
            self?.showCourseware()
        }
        cellItems.append(item)
        if shouldEnableDiscussions() {
            item = DashboardItem(title: OEXLocalizedString("COURSEDASHBOARD_DISCUSSION", nil), detail: OEXLocalizedString("COURSEDASHBOARD_DISCUSSION_DETAIL", nil)) {[weak self] () -> Void in
                self?.showDiscussions()
            }
            cellItems.append(item)
        }
        item = DashboardItem(title: OEXLocalizedString("COURSEDASHBOARD_HANDOUTS", nil), detail: OEXLocalizedString("COURSEDASHBOARD_HANDOUTS_DETAIL", nil)) {[weak self] () -> Void in
            self?.showHandouts()
        }
        cellItems.append(item)
        item = DashboardItem(title: OEXLocalizedString("COURSEDASHBOARD_ANNOUNCEMENTS", nil), detail: OEXLocalizedString("COURSEDASHBOARD_ANNOUNCEMENTS_DETAIL", nil)) {[weak self] () -> Void in
            self?.showAnnouncements()
        }
        cellItems.append(item)
    }
    
    
    func shouldEnableDiscussions() -> Bool {
        return self.environment.config!.shouldEnableDiscussions()
    }
    
    
    // MARK: - TableView Data and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else {
            return cellItems.count
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //TODO: this the temp height for each cell, adjust it when final UI is ready.
        if indexPath.section == 0 {
            return 190.0
        }else{
            return 80.0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseDashboardCourseInfoCell.identifier, forIndexPath: indexPath) as! CourseDashboardCourseInfoCell
            
            cell.titleLabel.text = self.course.name
            cell.detailLabel.text = self.course.org + " | " + self.course.number
            
            //TODO: the way to load image is not perfect, need to do refactoring later
            cell.course = self.course
            cell.setCoverImage()
            
            return cell
        }else{
            let cell = tableView.dequeueReusableCellWithIdentifier(CourseDashboardCell.identifier, forIndexPath: indexPath) as! CourseDashboardCell
            
            let dashboardItem = cellItems[indexPath.row]
            
            cell.titleLabel.text = dashboardItem.title
            cell.detailLabel.text = dashboardItem.detail
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        
        if indexPath.section == 1 {
            let dashboardItem = cellItems[indexPath.row]
            dashboardItem.action()
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

