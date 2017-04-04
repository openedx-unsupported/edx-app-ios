//
//  HTMLBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class HTMLBlockViewController: UIViewController, CourseBlockViewController, PreloadableBlockController {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider
    
    public let courseID : String
    public let blockID : CourseBlockID?
    
    private let webController : AuthenticatedWebViewController
    
    private let loader = BackedStream<CourseBlock>()
    private let courseQuerier : CourseOutlineQuerier
    
    public init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.courseID = courseID
        self.blockID = blockID
        
        webController = AuthenticatedWebViewController(environment: environment)
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        
        super.init(nibName : nil, bundle : nil)
        
        addChildViewController(webController)
        webController.didMove(toParentViewController: self)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webController.view)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }
    
    private func loadData() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(id: self.blockID).firstSuccess())
            loader.listen (self, success : {[weak self] block in
                if let url = block.blockURL {
                    let request = NSURLRequest(url: url as URL)
                    self?.webController.loadRequest(request: request)
                }
                else {
                    self?.webController.showError(error: nil)
                }
            }, failure : {[weak self] error in
                self?.webController.showError(error: error)
            })
        }
    }
    
    public func preloadData() {
        let _ = self.view
        loadData()
    }
}
