//
//  CourseCatalogViewController.swift
//  edX
//
//  Created by Akiva Leffert on 11/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCatalogViewController: UIViewController {
    typealias Environment = protocol<NetworkManagerProvider, OEXSessionProvider>
    
    private let environment : Environment
    
    init(environment : Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        self.navigationItem.title = Strings.findCourses
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var stream : Stream<[OEXCourse]> = {
        let stream : Stream<[OEXCourse]>
        if let username = self.environment.session.currentUser?.username {
            let request = CourseCatalogAPI.getCourseCatalog(username)
            stream = self.environment.networkManager.streamForRequest(request)
        }
        else {
            stream = Stream()
            preconditionFailure("Shouldn't be showing course catalog without logged in user")
        }
        return stream
    }()
    
    private lazy var tableController : CoursesTableViewController = {
        return CoursesTableViewController(courseStream: self.stream)
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        
        self.view.addSubview(tableController.view)
        tableController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
    }
}

// Testing only
extension CourseCatalogViewController {
    
    var t_loaded : Stream<()> {
        return self.stream.map {_ in
            return
        }
    }

}