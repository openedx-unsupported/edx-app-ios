//
//  DiscoveryViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 11/19/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class DiscoveryViewController: UIViewController, InterfaceOrientationOverriding {

    private var environment: RouterEnvironment
    private var bottomSpace: CGFloat {
        guard let bottomBar = bottomBar else { return StandardVerticalMargin }
        return bottomBar.frame.height + StandardVerticalMargin
    }
    private(set) var bottomBar: UIView?
    private let searchQuery: String?
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
    
    private func configureDiscoveryController() {
        guard environment.config.discovery.course.isEnabled else { return }

        let coursesController = self.environment.config.discovery.course.type == .webview ? OEXFindCoursesViewController(environment: environment, showBottomBar: false, bottomBar: bottomBar, searchQuery: self.searchQuery) : CourseCatalogViewController(environment: self.environment)

        addChild(coursesController)
        didMove(toParent: self)
        coursesController.view.frame = containerView.frame
        containerView.addSubview(coursesController.view)

    }
    
    private func setupView() {
        addSubViews()
        configureDiscoveryController()
        setupBottomBar()
        setupConstraints()
        view.backgroundColor = environment.styles.standardBackgroundColor()
    }

    
    private func addSubViews() {
        view.addSubview(containerView)
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
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(view).offset(StandardVerticalMargin)
            make.bottom.equalTo(view).offset(bottomSpace)
        }
    }

    func index(for segmentType: Int) -> Int {
        let requiredIndex = 0
        return requiredIndex
    }
}
