//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {

    let blockID : CourseBlockID
    let courseID : String
    let messageView : IconMessageView
    
    override func viewDidLoad() {
        makeUI()
    }
    
    init(blockID : CourseBlockID, courseID : String) {
        self.blockID = blockID
        self.courseID = courseID
        messageView = IconMessageView(icon: Icon.CourseUnknownContent, message: OEXLocalizedString("COURSE_CONTENT_UNKNOWN", nil), buttonTitle : OEXLocalizedString("COURSE_UNKNOWN_BUTTON_TITLE", nil), styles: OEXStyles.sharedStyles())
        
        //TODO : Add action to bottomButton
//        messageView.bottomButton.oex_addAction({ (action : AnyObject!) -> Void in
//            println("Do something with the view on web button")
//        }, forEvents: UIControlEvents.TouchUpInside)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func makeUI()
    {
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.view.addSubview(messageView)
        messageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self.view)
        }
    }
    
    
}
