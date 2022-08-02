//
//  LearnContainerViewController.swift
//  edX
//
//  Created by Muhammad Umer on 02/06/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class LearnContainerViewController: UIViewController {
    enum Component: LearnContainerHeaderItem, CaseIterable {
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
        
        static func index(of component: Component) -> Int {
            for (index, value) in Component.allCases.enumerated() {
                if value == component {
                    return index
                }
            }
            return 0
        }
    }
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & ServerConfigProvider & OEXSessionProvider
    
    private let environment: Environment
    
    private lazy var components: [LearnContainerHeaderItem] = {
        var items: [LearnContainerHeaderItem] = []
        items.append(Component.courses)
        if programsEnabled {
            items.append(Component.programs)
        }
        return items
    }()
    
    private lazy var headerView = LearnContainerHeaderView(items: components)
    
    private let container = UIView()
    private let coursesViewController: EnrolledCoursesViewController
    private var programsViewController: ProgramsViewController?
    
    private var selectedComponent: Component?
    
    private var programsEnabled: Bool {
        return environment.config.programConfig.enabled && environment.config.programConfig.programURL != nil
    }
    
    private var visibleViewController: UIViewController?
    
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
        visibleViewController = controller
        
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

extension LearnContainerViewController {
    func switchTo(component: Component, url: URL? = nil) {
        guard let visibleViewController = visibleViewController else { return }
        
        switch component {
        case .courses:
            if !visibleViewController.isKind(of: EnrolledCoursesViewController.self) {
                headerView.updateHeader(at: Component.index(of: component))
                update(component: component)
            }
        case .programs:
            if !visibleViewController.isKind(of: ProgramsViewController.self) {
                headerView.updateHeader(at: Component.index(of: component))
                update(component: component)
            }
            if let url = url {
                programsViewController?.loadPrograms(with: url)
            }
        }
    }
}

extension LearnContainerViewController: LearnContainerHeaderViewDelegate {
    func didTapOnDropDown(item: LearnContainerHeaderItem) {
        guard let component = item as? Component else { return }
        update(component: component)
    }
}

