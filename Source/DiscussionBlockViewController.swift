//
//  DiscussionBlockViewController.swift
//  edX
//
//  Created by Saeed Bashir on 5/27/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class DiscussionBlockViewController: UIViewController, CourseBlockViewController, CourseBlockCompletionController {
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider & DataManagerProvider & OEXConfigProvider
    
    let courseID: String
    let blockID : CourseBlockID?
    
    var block: CourseBlock? {
        return courseQuerier.blockWithID(id: blockID).firstSuccess().value
    }
    
    private let courseQuerier: CourseOutlineQuerier
    
    private let topicID: String?
    private let environment: Environment
    private let postsController: PostsViewController

    init(blockID: CourseBlockID?, courseID : String, topicID: String?, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.topicID = topicID
        self.environment = environment
        self.courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        
        self.postsController = PostsViewController(environment: self.environment, courseID: self.courseID, topicID: self.topicID)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        markBlockAsComplete()
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
    
    private func setupView() {
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        addChild(postsController)
        postsController.didMove(toParent: self)
        view.addSubview(postsController.view)
    }
    
    func markBlockAsComplete() {
         block?.completion = true
        
        guard let blockID = blockID,
              let username = OEXSession.shared()?.currentUser?.username else { return }
        let networkRequest = BlockCompletionApi.blockCompletionRequest(username: username, courseID: courseID, blockID: blockID)
        environment.networkManager.taskForRequest(networkRequest) { _ in }
    }
}
