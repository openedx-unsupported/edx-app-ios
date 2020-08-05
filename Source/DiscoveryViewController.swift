//
//  DiscoveryViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

 enum SegmentOption: Int {
    case course, program, degree
    static let options = [course, program, degree]
    
    var title: String {
        switch self {
        case .course:
            return Strings.courses
        case .program:
            return Strings.programs
        case .degree:
            return Strings.degrees
        }
    }
}

class DiscoveryViewController: UIViewController, InterfaceOrientationOverriding {
    
    private var segmentItems : [SegmentItem] = []
    private var environment: RouterEnvironment
    private let segmentControlHeight: CGFloat = 40.0
    private var bottomSpace: CGFloat {
        guard let bottomBar = bottomBar else { return StandardVerticalMargin }
        return bottomBar.frame.height + StandardVerticalMargin
    }
    private(set) var bottomBar: UIView?
    private let searchQuery: String?
    
    lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        let styles = self.environment.styles
        control.selectedSegmentIndex = SegmentOption.course.rawValue
        control.tintColor = styles.primaryBaseColor()
        control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: styles.neutralWhite()], for: .selected)
        control.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: styles.neutralBlack()], for: .normal)
        return control
    }()
    
    lazy var containerView = UIView()
 
    init(with environment: RouterEnvironment, bottomBar: UIView?, searchQuery: String?) {
        self.environment = environment
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if environment.session.currentUser != nil {
            bottomBar?.removeFromSuperview()
        }
        tabBarController?.navigationItem.title = Strings.discover
        navigationItem.title = Strings.discover
    }
    
    private func prepareSegmentViewData() {
        segmentItems = []
        var index = 0
        var item : SegmentItem
        for option in SegmentOption.options {
            switch option {
            case .course:
                guard environment.config.discovery.course.isEnabled else { break }
                let coursesController = self.environment.config.discovery.course.type == .webview ? OEXFindCoursesViewController(environment: environment, showBottomBar: false, bottomBar: bottomBar, searchQuery: self.searchQuery) : CourseCatalogViewController(environment: self.environment)
                item = SegmentItem(title: option.title, viewController: coursesController, index: index, type: option.rawValue, analyticsScreenName: OEXAnalyticsScreenFindCourses)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title, at: index, animated: false)
                index = segmentItems.count
            case .program:
                guard environment.config.discovery.program.isEnabled else { break }
                let programDiscoveryViewController = ProgramsDiscoveryViewController(with: environment, showBottomBar: false, bottomBar: bottomBar)
                programDiscoveryViewController.view.isHidden = true
                item = SegmentItem(title: option.title, viewController: programDiscoveryViewController, index: index, type: option.rawValue, analyticsScreenName: AnalyticsScreenName.DiscoverProgram.rawValue)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title, at: index, animated: false)
                index = segmentItems.count
            case .degree:
                guard environment.config.discovery.degree.isEnabled else { break }
                let degreesViewController = DegreesViewController(with: environment, showBottomBar: false, bottomBar: bottomBar)
                degreesViewController.view.isHidden = true
                item = SegmentItem(title: option.title, viewController: degreesViewController, index: index, type: option.rawValue, analyticsScreenName: AnalyticsScreenName.DiscoverDegree.rawValue)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title, at: index, animated: false)
                index = segmentItems.count
            }
        }
        segmentedControl.selectedSegmentIndex = 0
    }
    
    private func setupView() {
        prepareSegmentViewData()
        addSubViews()
        setupBottomBar()
        setupConstraints()
        view.backgroundColor = environment.styles.standardBackgroundColor()
        segmentedControl.oex_addAction({ [weak self] control in
            if let segmentedControl = control as? UISegmentedControl {
                self?.controllerVisibility(with: segmentedControl.selectedSegmentIndex)
            }
            else {
                assert(true, "Invalid control")
            }
        }, for: .valueChanged)
    }
    
    private func controllerVisibility(with segmentIndex: Int) {
        
        for item in segmentItems {
            if item.index == segmentIndex {
                item.viewController.view.isHidden = false
                environment.analytics.trackScreen(withName: item.analyticsScreenName)
            }
            else {
                item.viewController.view.isHidden = true
            }
        }
    }
    
    private func addSubViews() {
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        for item in segmentItems {
            let controller = item.viewController
            addChild(controller)
            didMove(toParent: self)
            controller.view.frame = containerView.frame
            containerView.addSubview(controller.view)
        }
    }
    
    private func setupBottomBar() {
        guard let bottomBar = bottomBar,
            environment.session.currentUser == nil else { return }
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
        }
        bottomBar.bringSubviewToFront(view)
    }
    
    private func setupConstraints() {
        segmentedControl.snp.makeConstraints { make in
            make.height.equalTo(segmentControlHeight)
            make.leading.equalTo(view).offset(StandardHorizontalMargin)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin)
            make.top.equalTo(view).offset(StandardVerticalMargin)
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(segmentedControl.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(view).offset(bottomSpace)
        }
    }

    func index(for segmentType: Int) -> Int {
        var requiredIndex = 0
        for item in segmentItems {
            if item.type == segmentType {
                requiredIndex = item.index
                break
            }
        }
        return requiredIndex
    }
    
    // MARK: Deep Linking
    func switchSegment(with type: DeepLinkType) {
        switch type {
        case .courseDiscovery, .courseDetail:
            let selectedIndex = index(for: SegmentOption.course.rawValue)
            segmentedControl.selectedSegmentIndex = selectedIndex
            controllerVisibility(with: selectedIndex)
            break
        case .programDiscovery, .programDiscoveryDetail:
            let selectedIndex = index(for: SegmentOption.program.rawValue)
            segmentedControl.selectedSegmentIndex = selectedIndex
            controllerVisibility(with: selectedIndex)
        case .degreeDiscovery, .degreeDiscoveryDetail:
            let selectedIndex = index(for: SegmentOption.degree.rawValue)
            segmentedControl.selectedSegmentIndex = selectedIndex
            controllerVisibility(with: selectedIndex)
        default:
            break
        }
    }
    
    func segmentType(of selectedIndex: Int) -> Int {
        var segmentType = SegmentOption.course.rawValue
        for item in segmentItems {
            if item.index == selectedIndex {
                segmentType = item.type
            }
        }
        return segmentType
    }
}
