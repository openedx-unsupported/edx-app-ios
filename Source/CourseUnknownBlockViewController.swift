//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    struct Environment {
        let dataManager : DataManager
        let styles : OEXStyles
    }
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    let messageView : IconMessageView
    
    var loader : Promise<CourseBlock>?
    init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        messageView = IconMessageView(icon: Icon.CourseUnknownContent, message: OEXLocalizedString("COURSE_CONTENT_UNKNOWN", nil), buttonTitle : OEXLocalizedString("OPEN_IN_BROWSER", nil), styles: self.environment.styles)
        
        super.init(nibName: nil, bundle: nil)
        
        
        messageView.bottomButton.oex_addAction({[weak self] _ in
            self?.loader?.then {block -> Void in
                block.webURL.map {
                    UIApplication.sharedApplication().openURL($0)
                }
            }
        }, forEvents: UIControlEvents.TouchUpInside)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = self.environment.styles.standardBackgroundColor()
        self.view.addSubview(messageView)
        messageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loader?.value == nil {
            loader = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID).blockWithID(self.blockID)
        }
    }
    
}
