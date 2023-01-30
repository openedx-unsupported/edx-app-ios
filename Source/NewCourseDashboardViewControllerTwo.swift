//
//  NewCourseDashboardViewControllerTwo.swift
//  edX
//
//  Created by MuhammadUmer on 16/12/2022.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class NewCourseDashboardViewControllerTwo: UIViewController {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider & RemoteConfigProvider & ServerConfigProvider
    
    private let courseStream: BackedStream<UserCourseEnrollment>
    private let loadStateController: LoadStateViewController
            
    private let environment: Environment
    private let courseID: String
    private let screen: CourseUpgradeScreen = .courseDashboard
    
    init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.courseStream = BackedStream<UserCourseEnrollment>()
        self.loadStateController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let headerContainer = UIView()
    let container = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        view.addSubview(headerContainer)
        view.addSubview(container)
        
        headerContainer.snp.makeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.top.equalTo(safeTop)
            make.height.equalTo(200)
        }
        
        container.snp.makeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.top.equalTo(headerContainer.snp.bottom)
            make.bottom.equalTo(safeBottom)
        }
    }
}
