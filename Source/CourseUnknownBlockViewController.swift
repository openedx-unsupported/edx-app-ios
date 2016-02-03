//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = protocol<DataManagerProvider>
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    let messageView : IconMessageView
    
    var loader : Stream<NSURL?>?
    init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        messageView = IconMessageView(icon: Icon.CourseUnknownContent, message: Strings.courseContentUnknown)
        
        super.init(nibName: nil, bundle: nil)
        
        
        messageView.buttonInfo = MessageButtonInfo(title : Strings.openInBrowser)
            {
            [weak self] in
            self?.loader?.listen(self!, success : {URL -> Void in
                if let URL = URL {
                    UIApplication.sharedApplication().openURL(URL)
                }
            }, failure : {_ in
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.view.addSubview(messageView)
        
    }
    
    override func updateViewConstraints() {
        
        switch UIDevice.currentDevice().orientation {
        case .Portrait, .FaceUp, .FaceDown :
            applyPortraitConstraints()
        case .LandscapeLeft, .LandscapeRight:
            applyLandscapeConstraints()
        default:
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        messageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    private func applyLandscapeConstraints() {
        messageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
            make.bottom.equalTo(view.snp_bottom).offset(-44)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loader?.value == nil {
            loader = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID).blockWithID(self.blockID).map {
                return $0.webURL
            }.firstSuccess()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        
        if UIDevice.currentDevice().orientation != .LandscapeLeft || UIDevice.currentDevice().orientation != .LandscapeRight {
            UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        }
        
        super.viewDidAppear(animated)
    }
    
}
