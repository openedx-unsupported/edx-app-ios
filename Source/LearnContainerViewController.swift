//
//  LearnContainerViewController.swift
//  edX
//
//  Created by Muhammad Umer on 02/06/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class LearnContainerViewController: UIViewController {
    enum Controller: LearnContainerHeaderItem {
        case courses
        case programs
        
        var value: String {
            switch self {
            case .courses:
                return Strings.myCourses
            case .programs:
                return Strings.myPrograms
            }
        }
        
        var index: Int {
            switch self {
            case .courses:
                return 0
            case .programs:
                return 1
            }
        }
        
        static var allCases: [LearnContainerHeaderItem] {
            return [Controller.courses, Controller.programs]
        }
    }
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & RemoteConfigProvider & OEXSessionProvider
    
    let environment: Environment
    
    private let headerView = LearnContainerHeaderView(items: Controller.allCases)
    private let container = UIView()
    
    private let coursesViewController: EnrolledCoursesViewController
    private var programsViewController: ProgramsViewController?
    
    private var selectedController: Controller?
    
    init(environment: Environment) {
        self.environment = environment
        self.coursesViewController = EnrolledCoursesViewController(environment: environment, headerView: headerView)
        if environment.config.programConfig.enabled,
           let programsURL = environment.config.programConfig.programURL {
            self.programsViewController = ProgramsViewController(environment: environment, programsURL: programsURL)
        }
        super.init(nibName: nil, bundle: nil)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView.delegate = self
        update(controller: .courses)
    }
    
    private func setupViews() {
        view.accessibilityIdentifier = "LearnContainerViewController:view"
        container.accessibilityIdentifier = "LearnContainerViewController:container-view"
        headerView.accessibilityIdentifier = "LearnContainerViewController:header-view"
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        view.addSubview(headerView)
        view.addSubview(container)
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(80)
        }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
    }
    
    private func update(controller: Controller) {
        guard selectedController != controller,
              let programsViewController = programsViewController else { return }
        
        switch controller {
        case .courses:
            removeViewController(programsViewController) { [weak self] in
                guard let weakSelf = self else { return}
                weakSelf.addViewController(weakSelf.coursesViewController)
            }
        case .programs:
            removeViewController(coursesViewController) { [weak self] in
                guard let weakSelf = self else { return}
                weakSelf.addViewController(programsViewController)
            }
        }
        
        selectedController = controller
    }
    
    private func addViewController(_ controller: UIViewController, completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.3, options: .curveEaseIn) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.addChild(controller)
            weakSelf.container.addSubview(controller.view)
            controller.view.frame = weakSelf.container.bounds
            controller.didMove(toParent: self)
        } completion: { _ in
            completion?()
        }
    }
    
    private func removeViewController(_ controller: UIViewController, completion: (() -> ())? = nil) {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.3, options: .curveEaseOut) {
            controller.willMove(toParent: nil)
            controller.view.removeFromSuperview()
            controller.removeFromParent()
        } completion: { _ in
            completion?()
        }
    }
}

extension LearnContainerViewController: LearnContainerHeaderViewDelegate {
    func didTapOnDropDown(item: LearnContainerHeaderItem) {
        guard let controller = item as? Controller else { return }
        update(controller: controller)
    }
}

