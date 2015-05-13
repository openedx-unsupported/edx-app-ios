//
//  CourseDashboardViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class CourseDashboardViewControllerEnvironment : NSObject {
    
    let config : OEXConfig?
    weak var router : OEXRouter?
    
    
    init(router : OEXRouter? , config : OEXConfig)
    {
        self.config = config
        self.router = router;
    }
}

class CourseDashboardViewController: UIViewController {

    let environment : CourseDashboardViewControllerEnvironment!
    var course : OEXCourse!
    var discussionsButton : UIButton?
    
    init(environment: CourseDashboardViewControllerEnvironment , course : OEXCourse)
    {
        self.environment = environment;
        self.course = course;
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeStubUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func makeStubUI() {
        self.view.backgroundColor = UIColor.whiteColor()
        
        weak var weakSelf = self;
        
        var buttons : [UIButton] = []
        
        var coursewareButton : UIButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        coursewareButton.setTitle("Cøürseware!", forState: UIControlState.Normal)
        coursewareButton.oex_addAction({ (control) -> Void in
                weakSelf?.showCourseware()
        }, forEvents: UIControlEvents.TouchUpInside)
        buttons.append(coursewareButton)
        
        var announcementsButton : UIButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        announcementsButton.setTitle("Ånnouncements!", forState: UIControlState.Normal)
        announcementsButton.oex_addAction({ (control) -> Void in
                weakSelf?.showAnnouncements()
        }, forEvents: UIControlEvents.TouchUpInside)
        buttons.append(announcementsButton)
        
        var handoutsButton : UIButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
        handoutsButton.oex_addAction({ (control) -> Void in
            weakSelf?.showHandouts()
        }, forEvents: UIControlEvents.TouchUpInside)
        handoutsButton.setTitle("Handøüts!", forState: UIControlState.Normal)
        buttons.append(handoutsButton)
        
        if (self.environment.config!.shouldEnableDiscussions()){
            self.discussionsButton = UIButton.buttonWithType(UIButtonType.System) as? UIButton
            discussionsButton!.oex_addAction({ (control) -> Void in
                weakSelf?.showDiscussions()
            }, forEvents: UIControlEvents.TouchUpInside)
            discussionsButton!.setTitle("Discussiøns!", forState: UIControlState.Normal)
            buttons.append(discussionsButton!)
        }
        
        var container = UIView(frame: CGRectZero)
        self.view.addSubview(container)

        
        var prev : UIButton?
        for btn in buttons {
            container.addSubview(btn)
            btn.snp_makeConstraints({ (make) -> Void in
                    if let p = prev{
                        make.top.equalTo(p.snp_bottom).offset(20)
                    }
                    make.centerX.equalTo(container)
                    prev = btn
                })
            }
        
        container.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self.view)
            make.top.equalTo(buttons.first!)
            make.bottom.equalTo((buttons.last!).snp_bottom)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
        }
        
    }
    
    
    
    func showCourseware() {
        self.environment.router?.showCoursewareForCourseWithID(self.course.course_id, fromController: self)
    }
    
    func showHandouts() {
        //TODO
    }
    
    func showDiscussions() {
        //TODO
    }
    
    func showAnnouncements() {
        //TODO
    }
    
    
    

}

extension CourseDashboardViewController { //Testing
    
    func t_canVisitDiscussions() -> Bool {
        return self.discussionsButton?.superview != nil;
    }
    
}

