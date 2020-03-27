//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCatalogViewController: UIViewController, CoursesCollectionViewControllerDelegate, InterfaceOrientationOverriding {
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXSessionProvider & OEXConfigProvider & OEXAnalyticsProvider
    
    private let environment : Environment
    private let collectionController : CoursesCollectionViewController
    private let loadController = LoadStateViewController()
    private let insetsController = ContentInsetsController()
    
    init(environment : Environment) {
        self.environment = environment
        self.collectionController = CoursesCollectionViewController(environment: environment, context: .CourseCatalog)
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.accessibilityIdentifier = "CourseCatalogViewController:cancel-bar-button-item"
        view.accessibilityIdentifier = "course-catalog-screen"

        setupAndLoadCourseCatalog()
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
        return PaginationController(paginator: paginator, collectionView: self.collectionController.collectionView)
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenFindCourses)
    }

    private func setupAndLoadCourseCatalog() {
        addChild(collectionController)
        collectionController.didMove(toParent: self)
        self.loadController.setupInController(controller: self, contentView: collectionController.view)

        self.view.addSubview(collectionController.view)
        collectionController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }

        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()

        collectionController.delegate = self

        paginationController.stream.listen(self, success:
            {[weak self] courses in
                self?.setupLoadingState(courses: courses)
                self?.collectionController.courses = courses
                self?.collectionController.collectionView.reloadData()
            }, failure: {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            }
        )
        paginationController.loadMore()

        insetsController.setupInController(owner: self, scrollView: collectionController.collectionView)
        insetsController.addSource(
            // add a little padding to the bottom since we have a big space between
            // each course card
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
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
