//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCatalogViewController: UIViewController, CoursesContainerViewControllerDelegate, InterfaceOrientationOverriding {
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXSessionProvider & OEXConfigProvider & OEXAnalyticsProvider & OEXInterfaceProvider
    
    private let environment : Environment
    private let coursesContainer : CoursesContainerViewController
    private let loadController = LoadStateViewController()
    private let insetsController = ContentInsetsController()
    
    init(environment : Environment) {
        self.environment = environment
        coursesContainer = CoursesContainerViewController(environment: environment, context: .courseCatalog)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate lazy var paginationController : PaginationController<OEXCourse> = {
        let username = environment.session.currentUser?.username ?? ""
        precondition(username != "", "Shouldn't be showing course catalog without a logged in user")
        let organizationCode =  environment.config.organizationCode()
        
        let paginator = WrappedPaginator(networkManager: environment.networkManager) { page in
            return CourseCatalogAPI.getCourseCatalog(userID: username, page: page, organizationCode: organizationCode)
        }
        return PaginationController(paginator: paginator, collectionView: coursesContainer.collectionView)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = Strings.findCourses
        tabBarController?.navigationItem.title = Strings.findCourses
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenFindCourses)
    }
    
    private func setupView() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.accessibilityIdentifier = "CourseCatalogViewController:cancel-bar-button-item"
        view.accessibilityIdentifier = "course-catalog-screen"
        
        setupAndLoadCourseCatalog()
    }

    private func setupAndLoadCourseCatalog() {
        addChild(coursesContainer)
        coursesContainer.didMove(toParent: self)
        loadController.setupInController(controller: self, contentView: coursesContainer.view)

        view.addSubview(coursesContainer.view)
        coursesContainer.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }

        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()

        coursesContainer.delegate = self

        paginationController.stream.listen(self, success:
            {[weak self] courses in
                self?.setupLoadingState(courses: courses)
                self?.coursesContainer.courses = courses
                self?.coursesContainer.collectionView.reloadData()
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            }
        )
        paginationController.loadMore()

        insetsController.setupInController(owner: self, scrollView: coursesContainer.collectionView)
        insetsController.addSource(
            // add a little padding to the bottom since we have a big space between
            // each course card
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    
    func coursesContainerChoseCourse(course: OEXCourse) {
        guard let courseID = course.course_id else {
            return
        }
        environment.router?.showCourseCatalogDetail(courseID: courseID, fromController:self)
    }
    
    func showUpgradeCourseDetailView() {
        
    }
    
    func setupLoadingState(courses: [OEXCourse]) {
        if courses.count > 0 {
            loadController.state = .Loaded
        } else {
            let error = NSError.oex_error(with: .unknown, message: Strings.findCoursesNoAvailableCourses)
            loadController.state = LoadState.failed(error: error, icon: Icon.UnknownError)
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
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
