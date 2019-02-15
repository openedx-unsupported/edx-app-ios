//
//  DiscussionBlockViewController.swift
//  edX
//
//  Created by Saeed Bashir on 5/27/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionBlockViewController: UIViewController,CourseBlockViewController {
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    let courseID: String
    let blockID : CourseBlockID?
    private let topicID: String?
    private let environment : Environment
    private let postsController:PostsViewController
    
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
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        addChild(postsController)
        postsController.didMove(toParent: self)
        
        view.addSubview(postsController.view)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        postsController.view.snp.remakeConstraints { make in
            make.top.equalTo(safeTop)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(safeBottom).offset(-barHeight)
        }
    }
}
