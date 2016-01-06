//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCatalogViewController: UIViewController, CoursesTableViewControllerDelegate {
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXSessionProvider>
    
    private let environment : Environment
    private let tableController : CoursesTableViewController
    private let loadController = LoadStateViewController()
    private let insetsController = ContentInsetsController()
    
    init(environment : Environment) {
        self.environment = environment
        self.tableController = CoursesTableViewController(environment: environment, context: .CourseCatalog)
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var paginationController : TablePaginationController<OEXCourse> = {
        let username = self.environment.session.currentUser?.username ?? ""
        precondition(username != "", "Shouldn't be showing course catalog without a logged in user")
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return CourseCatalogAPI.getCourseCatalog(username, page: page)
        }
        return TablePaginationController(paginator: paginator, tableView: self.tableController.tableView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        self.loadController.setupInController(self, contentView: tableController.view)
        
        self.view.addSubview(tableController.view)
        tableController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        tableController.delegate = self

        paginationController.stream.listen(self, success:
            {[weak self] courses in
                self?.loadController.state = .Loaded
                self?.tableController.courses = courses
                self?.tableController.tableView.reloadData()
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            }
        )
        paginationController.loadMore()
        
        insetsController.setupInController(self, scrollView: tableController.tableView)
        insetsController.addSource(
            // add a little padding to the bottom since we have a big space between
            // each course card
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    
    func coursesTableChoseCourse(course: OEXCourse) {
        guard let courseID = course.course_id else {
            return
        }
        self.environment.router?.showCourseCatalogDetail(courseID, fromController:self)
    }
}

// Testing only
extension CourseCatalogViewController {
    
    var t_loaded : Stream<()> {
        return self.paginationController.stream.map {_ in
            return
        }
    }

}
