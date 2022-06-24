//
//  LearnContainerViewController.swift
//  edX
//
//  Created by Muhammad Umer on 02/06/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class LearnContainerViewController: UIViewController {
    enum Component: LearnContainerHeaderItem {
        case courses
        case programs
        
        var title: String {
            switch self {
            case .courses:
                return Strings.myCourses
            case .programs:
                return Strings.myPrograms
            }
        }
    }
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & RemoteConfigProvider & OEXSessionProvider
    
    private let environment: Environment
    
    private lazy var headerView: LearnContainerHeaderView = {
        var items: [LearnContainerHeaderItem] = []
        items.append(Component.courses)
        if programsEnabled {
            items.append(Component.programs)
        }
        return LearnContainerHeaderView(items: items)
    }()
    private let container = UIView()
    
    private let coursesViewController: EnrolledCoursesViewController
    private var programsViewController: ProgramsViewController?
    
    private var selectedComponent: Component?
    
    private var programsEnabled: Bool {
        return environment.config.programConfig.enabled && environment.config.programConfig.programURL != nil
    }
    
    init(environment: Environment) {
        self.environment = environment
        self.coursesViewController = EnrolledCoursesViewController(environment: environment)
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
        update(component: .courses)
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
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.height.equalTo(LearnContainerHeaderView.height)
        }
        
        container.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
    }
    
    private func update(component: Component) {
        guard selectedComponent != component else { return }
        
        switch component {
        case .courses:
            if let programsViewController = programsViewController {
                removeViewController(programsViewController) { [weak self] in
                    guard let weakSelf = self else { return}
                    weakSelf.addViewController(weakSelf.coursesViewController)
                }
            }
            else {
                addViewController(coursesViewController)
            }
        case .programs:
            guard let programsViewController = programsViewController else { return }
            removeViewController(coursesViewController) { [weak self] in
                guard let weakSelf = self else { return}
                weakSelf.addViewController(programsViewController)
            }
        }
        
        selectedComponent = component
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
        guard let component = item as? Component else { return }
        update(component: component)
    }
}

