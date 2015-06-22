//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

let cellTypeTitleAndBy = 1
let cellTypeTitleOnly = 2


class PostsViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MenuOptionsDelegate {
    var environment: PostsViewControllerEnvironment!
    
    private let identifierTitleAndByCell = "TitleAndByCell"
    private let identifierTitleOnlyCell = "TitleOnlyCell"
    
    private var tableView: UITableView!
    private var viewSeparator: UIView!
    
    private let btnPosts = UIButton.buttonWithType(.System) as! UIButton
    private let btnActivity = UIButton.buttonWithType(.System) as! UIButton
    private let newPostButton = UIButton.buttonWithType(.System) as! UIButton
    
    var viewOption: UIView!
    var viewControllerOption: MenuOptionsViewController!
    let sortByOptions = [OEXLocalizedString("RECENT_ACTIVITY", nil) as String, OEXLocalizedString("MOST_ACTIVITY", nil) as String, OEXLocalizedString("MOST_VOTES", nil) as String]
    let filteringOptions = [OEXLocalizedString("ALL_POSTS", nil) as String, OEXLocalizedString("UNREAD", nil) as String, OEXLocalizedString("UNANSWERED", nil) as String]
    
    var isFilteringOptionsShowing: Bool?
    
    // TOOD: replace with API return
    var cellValues = [  ["type" : cellTypeTitleAndBy, "title": "Unread post title", "by": "STAFF", "count": 6],
        ["type" : cellTypeTitleAndBy, "title": "Read post with new comments", "by": "STAFF", "count": 5],
        ["type" : cellTypeTitleAndBy, "title": "Read post with read comments", "by": "COMMUNITY TA", "count": 9],
        ["type" : cellTypeTitleOnly, "title": "Unanswered question", "count": 12],
        ["type" : cellTypeTitleOnly, "title": "Answered question", "count": 16],
        ["type" : cellTypeTitleOnly, "title": "Unread post title that is really really very super long", "count": 96],
        ["type" : cellTypeTitleOnly, "title": "Unanswered question", "count": 36],
        ["type" : cellTypeTitleOnly, "title": "Answered question", "count": 66]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: replace the string with the text from API
        self.navigationItem.title = "Posts I'm Following"
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        btnPosts.setTitle(OEXLocalizedString("ALL_POSTS", nil), forState: .Normal)
        btnPosts.addTarget(self,
            action: "postsTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(btnPosts)
        
        btnPosts.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view).offset(20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(103)
        }
        
        btnActivity.setTitle(OEXLocalizedString("RECENT_ACTIVITY", nil), forState: .Normal)
        btnActivity.addTarget(self,
            action: "activityTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(btnActivity)
        
        btnActivity.snp_makeConstraints{ (make) -> Void in
            make.trailing.equalTo(view).offset(-20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(103)
        }
        
        newPostButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()
        
        let createAPostString = OEXLocalizedString("CREATE_A_NEW_POST", nil)
        let plainText = createAPostString.textWithIconFont(Icon.Create.textRepresentation)
        let styledText = NSMutableAttributedString(string: plainText)
        styledText.setSizeForText(plainText, textSizes: [createAPostString: 16, Icon.Create.textRepresentation: 12])
        styledText.addAttribute(NSForegroundColorAttributeName, value: OEXStyles.sharedStyles().neutralWhite(), range: NSMakeRange(0, count(plainText)))
 
        newPostButton.setAttributedTitle(styledText, forState: .Normal)
        newPostButton.contentVerticalAlignment = .Center

        weak var weakSelf = self
        newPostButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewPostFromController(weakSelf)
        }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(newPostButton)
        newPostButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(60)
            make.bottom.equalTo(view.snp_bottom)
        }
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        if let theTableView = tableView {
            theTableView.registerClass(PostTitleByTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleAndByCell)
            theTableView.registerClass(PostTitleTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleOnlyCell)
            theTableView.dataSource = self
            theTableView.delegate = self
            view.addSubview(theTableView)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(view)
                make.top.equalTo(btnPosts).offset(30)
                make.trailing.equalTo(view)
                make.bottom.equalTo(newPostButton.snp_top)
        }
        
        
        viewSeparator = UIView()
        viewSeparator.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        view.addSubview(viewSeparator)
        viewSeparator.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.dividerSize())
            make.top.equalTo(btnPosts.snp_bottom).offset(12)
        }
        
        tableView.reloadData()
    }
    
    func postsTapped(sender: AnyObject) {
        if isFilteringOptionsShowing != nil {
            return
        }
        
        let btnTapped = sender as! UIButton
        let buttonTitle = btnTapped.titleLabel?.text ?? ""
        
        isFilteringOptionsShowing = true
        
        viewControllerOption = MenuOptionsViewController()
        viewControllerOption.delegate​ = self
        viewControllerOption.options = filteringOptions
        viewControllerOption.selectedOptionIndex = find(filteringOptions, buttonTitle) ?? 0 as Int
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: viewControllerOption.menuWidth, height: viewControllerOption.menuHeight)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
            }, completion: nil)
    }
    
    func activityTapped(sender: AnyObject) {
        if isFilteringOptionsShowing != nil {
            return;
        }
        
        let btnTapped = sender as! UIButton
        let buttonTitle = btnTapped.titleLabel?.text ?? ""

        isFilteringOptionsShowing = false
        
        viewControllerOption = MenuOptionsViewController()
        viewControllerOption.delegate​ = self
        viewControllerOption.options = sortByOptions
        viewControllerOption.selectedOptionIndex = find(sortByOptions, buttonTitle) ?? 0 as Int
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: viewControllerOption.menuWidth, height: viewControllerOption.menuHeight)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
            }, completion: nil)
    }
    
    func optionSelected(selectedRow: Int, sender: AnyObject) {
        if isFilteringOptionsShowing! {
            btnPosts.setTitle(filteringOptions[selectedRow], forState: .Normal)
        }
        else {
            btnActivity.setTitle(sortByOptions[selectedRow], forState: .Normal)
        }
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: self.viewControllerOption.view.frame.origin.x, y: -101, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
            }, completion: {[weak self] (finished: Bool) in
                self!.viewControllerOption.view.removeFromSuperview()
                self!.isFilteringOptionsShowing = nil
            })
    }

    // MARK - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeTitleAndBy {
            return 70;
        }
        else {
            return 50;
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellValues.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeTitleAndBy {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleAndByCell, forIndexPath: indexPath) as! PostTitleByTableViewCell
            
            cell.typeButton.titleLabel?.font = Icon.fontWithSize(16)
            cell.typeButton.setTitle(Icon.Comments.textRepresentation, forState: .Normal)
            cell.typeButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)

            cell.titleLabel.text = cellValues[indexPath.row]["title"] as? String

            cell.byButton.titleLabel?.font = Icon.fontWithSize(12)
            cell.byButton.setTitle(Icon.User.textRepresentation, forState: .Normal)
            cell.byButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)

            cell.byLabel.text = cellValues[indexPath.row]["by"] as? String
            cell.countButton.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: .Normal)
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleOnlyCell, forIndexPath: indexPath) as! PostTitleTableViewCell

            cell.typeButton.titleLabel?.font = Icon.fontWithSize(16)
            cell.typeButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
            cell.typeButton.setTitle(Icon.Comments.textRepresentation, forState: .Normal)

            cell.titleLabel.text = cellValues[indexPath.row]["title"] as? String
            cell.countButton.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: UIControlState.Normal)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        environment.router?.showDiscussionResponsesFromController(self)
    }
}



