//
//  DiscussionBlockViewController.swift
//  edX
//
//  Created by Saeed Bashir on 5/27/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionBlockViewController: UIViewController,CourseBlockViewController {
    
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider>
    
    let courseID: String
    let topicID: String?
    let blockID : CourseBlockID?
    private let environment : Environment
    let postsController:PostsViewController
    
    
    init(blockID: CourseBlockID?, courseID : String, topicID: String?, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.topicID = topicID
        self.environment = environment
        
        self.postsController = PostsViewController(environment: self.environment, courseID: self.courseID, topicID: self.topicID)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        addChildViewController(postsController)
        postsController.didMoveToParentViewController(self)
        
        view.addSubview(postsController.view)
        postsController.view.snp_makeConstraints {make in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view).offset(-OEXStyles.sharedStyles().standardFooterHeight)
        }
    }
}