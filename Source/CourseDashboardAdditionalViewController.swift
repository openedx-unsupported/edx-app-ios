//
//  CourseDashboardAdditionalViewController.swift
//  edX
//
//  Created by Salman on 31/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol CourseDashboardItem {
    var identifier: String { get }
    var action:(() -> Void) { get }
    var height: CGFloat { get }
    
    func decorateCell(cell: UITableViewCell)
}

struct StandardCourseDashboardItem : CourseDashboardItem {
    let identifier = CourseDashboardCell.identifier
    let height:CGFloat = 85.0
    
    let title: String
    let detail: String
    let icon : Icon
    let action:(() -> Void)
    
    
    typealias CellType = CourseDashboardCell
    func decorateCell(cell: UITableViewCell) {
        guard let dashboardCell = cell as? CourseDashboardCell else { return }
        dashboardCell.useItem(item: self)
    }
}


class CourseDashboardAdditionalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    private let courseID: String
    private let environment: Environment
    private let enrollment: UserCourseEnrollment
    private let tableView: UITableView = UITableView()
    fileprivate var cellItems: [CourseDashboardItem] = []
    
    public init(environment: Environment, courseID: String, enrollment: UserCourseEnrollment) {
        self.environment = environment
        self.courseID = courseID
        self.enrollment = enrollment
        
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.shared().neutralXLight()
        
        
        tableView.isScrollEnabled = false
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        self.view.addSubview(tableView)
        
        // Register tableViewCell
        tableView.register(CourseDashboardCell.self, forCellReuseIdentifier: CourseDashboardCell.identifier)
        
        tableView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareTableViewData(enrollment: enrollment)
    }
    
    public func prepareTableViewData(enrollment: UserCourseEnrollment) {
        cellItems = []
        
        if shouldShowHandouts(course: enrollment.course) {
            let item = StandardCourseDashboardItem(title: Strings.Dashboard.courseHandouts, detail: Strings.Dashboard.courseHandoutsDetail, icon: .Handouts) {[weak self] () -> Void in
                self?.showHandouts()
            }
            cellItems.append(item)
        }
        
        if environment.config.isAnnouncementsEnabled {
            let item = StandardCourseDashboardItem(title: Strings.Dashboard.courseAnnouncements, detail: Strings.Dashboard.courseAnnouncementsDetail, icon: .Announcements) {[weak self] () -> Void in
                self?.showAnnouncements()
            }
            cellItems.append(item)
        }
        self.tableView.reloadData()
    }
    
    // MARK: - TableView Data and Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let dashboardItem = cellItems[indexPath.row]
        let height = dashboardItem.height
        return height
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dashboardItem = cellItems[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: dashboardItem.identifier, for: indexPath as IndexPath)
        dashboardItem.decorateCell(cell: cell)
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dashboardItem = cellItems[indexPath.row]
        dashboardItem.action()
    }
    
    private func showHandouts() {
        environment.router?.showHandoutsFromController(controller: self, courseID: courseID)
    }
    
    private func showAnnouncements() {
        environment.router?.showAnnouncementsForCourse(withID: courseID)
    }
    
    private func shouldShowHandouts(course: OEXCourse) -> Bool {
        return !(course.course_handouts?.isEmpty ?? true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}
