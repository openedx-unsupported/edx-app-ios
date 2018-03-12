//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCatalogViewController: UIViewController, CoursesTableViewControllerDelegate {
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXSessionProvider & OEXConfigProvider & OEXAnalyticsProvider
    
    private let environment : Environment
    private let tableController : CoursesTableViewController
    private let loadController = LoadStateViewController()
    private let insetsController = ContentInsetsController()
    
    init(environment : Environment) {
        self.environment = environment
        self.tableController = CoursesTableViewController(environment: environment, context: .CourseCatalog)
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate lazy var paginationController : PaginationController<OEXCourse> = {
        let username = self.environment.session.currentUser?.username ?? ""
        precondition(username != "", "Shouldn't be showing course catalog without a logged in user")
        let organizationCode =  self.environment.config.organizationCode()
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return CourseCatalogAPI.getCourseCatalog(userID: username, page: page, organizationCode: organizationCode)
        }
        return PaginationController(paginator: paginator, tableView: self.tableController.tableView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.accessibilityIdentifier = "course-catalog-screen";
        addChildViewController(tableController)
        tableController.didMove(toParentViewController: self)
        self.loadController.setupInController(controller: self, contentView: tableController.view)
        
        self.view.addSubview(tableController.view)
        tableController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        tableController.delegate = self

        paginationController.stream.listen(self, success:
            {[weak self] courses in
                self?.setupLoadingState(courses: courses)
                self?.tableController.courses = courses
                self?.tableController.tableView.reloadData()
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            }
        )
        paginationController.loadMore()
        
        insetsController.setupInController(owner: self, scrollView: tableController.tableView)
        insetsController.addSource(
            // add a little padding to the bottom since we have a big space between
            // each course card
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenFindCourses)
    }
    
    func coursesTableChoseCourse(course: OEXCourse) {
        guard let courseID = course.course_id else {
            return
        }
        self.environment.router?.showCourseCatalogDetail(courseID: courseID, fromController:self)
    }
    
    func setupLoadingState(courses: [OEXCourse]) {
        if courses.count > 0 {
            loadController.state = .Loaded
        } else {
            let error = NSError.oex_error(with: .unknown, message: Strings.findCoursesNoAvailableCourses)
            loadController.state = LoadState.failed(error: error, icon: Icon.UnknownError)
        }
    }
}

// Testing only
extension CourseCatalogViewController {
    
    var t_loaded : OEXStream<()> {
        return self.paginationController.stream.map {_ in
            return
        }
    }

}
