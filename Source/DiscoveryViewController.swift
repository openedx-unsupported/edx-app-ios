//
//  DiscoveryViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

 enum segment: Int {
    case courses
    case programs
    case degrees
}

class DiscoveryViewController: UIViewController, InterfaceOrientationOverriding {
    
    private enum segmentOptions: Int {
        case Course, Program, Degree
        static let options = [Course, Program, Degree]
        
        func title(config: OEXConfig? = nil) -> String {
            switch self {
            case .Course:
                return Strings.courses
            case .Program:
                return Strings.programs
            case .Degree:
                return Strings.degrees
            }
        }
    }
    
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
        control.selectedSegmentIndex = segment.courses.rawValue
        control.tintColor = styles.primaryBaseColor()
        control.setTitleTextAttributes([NSForegroundColorAttributeName: styles.neutralWhite()], for: .selected)
        control.setTitleTextAttributes([NSForegroundColorAttributeName: styles.neutralBlack()], for: .normal)
        return control
    }()
    
    lazy var containerView = UIView()
 
    init(with environment: RouterEnvironment, bottomBar: UIView?, searchQuery: String?) {
        self.environment = environment
        self.bottomBar = bottomBar
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if environment.session.currentUser != nil {
            bottomBar?.removeFromSuperview()
        }
    }
    
    private func prepareSegmentViewData() {
        segmentItems = []
        var index = 0
        var item : SegmentItem
        for option in segmentOptions.options {
            switch option {
            case .Course:
                guard environment.config.discovery.course.isEnabled else { break }
                let coursesController = self.environment.config.discovery.course.type == .webview ? OEXFindCoursesViewController(environment: environment, showBottomBar: false, bottomBar: bottomBar, searchQuery: self.searchQuery) : CourseCatalogViewController(environment: self.environment)
                item = SegmentItem(title: option.title(), viewController: coursesController, index: index)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title(), at: index, animated: false)
                index = segmentItems.count
            case .Program:
                guard environment.config.discovery.program.isEnabled else { break }
                let programDiscoveryViewController = ProgramsDiscoveryViewController(with: environment, showBottomBar: false, bottomBar: bottomBar)
                programDiscoveryViewController.view.isHidden = true
                item = SegmentItem(title: option.title(), viewController: programDiscoveryViewController, index: index)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title(), at: index, animated: false)
                index = segmentItems.count
            case .Degree:
                guard environment.config.discovery.degree.isEnabled else { break }
                let degreesViewController = DegreesViewController(with: environment, showBottomBar: false, bottomBar: bottomBar)
                degreesViewController.view.isHidden = true
                item = SegmentItem(title: option.title(), viewController: degreesViewController, index: index)
                segmentItems.append(item)
                segmentedControl.insertSegment(withTitle: option.title(), at: index, animated: false)
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
        navigationItem.title = Strings.discover
    }
    
    private func controllerVisibility(with segmentIndex: Int) {
        
        for item in segmentItems {
            if item.index == segmentIndex {
                item.viewController.view.isHidden = false
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
            addChildViewController(controller)
            didMove(toParentViewController: self)
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
        bottomBar.bringSubview(toFront: view)
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

    // MARK: Deep Linking    
    func switchSegment(with type: DeepLinkType) {
        switch type {
        case .courseDiscovery:
            segmentedControl.selectedSegmentIndex = segment.courses.rawValue
            controllerVisibility(with: segment.courses.rawValue)
            break
        case .programDiscovery, .programDetail:
            segmentedControl.selectedSegmentIndex = segment.programs.rawValue
            controllerVisibility(with: segment.programs.rawValue)
        default:
            break
        }
    }
}
