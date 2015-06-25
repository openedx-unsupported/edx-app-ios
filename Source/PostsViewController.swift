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

struct DiscussionPostItem: DiscussionItem{
    let cellType: Int
    let title: String
    let body: String
    let author: String
    let createdAt: NSDate
    let count: Int
    let threadID: String
}

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
    
    var posts : [DiscussionPostItem]  = []
    
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
        
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            after: style.attributedStringWithText(OEXLocalizedString("CREATE_A_NEW_POST", nil)))
        newPostButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
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
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        getAndShowThreads()
    }
    
    func getAndShowThreads() {
        // get threads (posts)
        let apiRequest = NetworkRequest(
            method : HTTPMethod.GET,
            path : "/api/discussion/v1/threads/",
            query: ["course_id" : JSON("course-v1:edX+DemoX+Demo_Course"), "following": true],
            requiresAuth : true,
            deserializer : {(response, data) -> Result<NSObject> in
                var dataString = NSString(data: data!, encoding:NSUTF8StringEncoding)
                println("\(response), \(dataString)")
                
                let json = JSON(data: data!)
                if let results = json["results"].array {
                    self.posts.removeAll(keepCapacity: true)
                    for result in results {
                        let item = DiscussionPostItem(cellType: cellTypeTitleAndBy, // item["raw_body"]
                            title: result["title"].string!,
                            body: result["raw_body"].string!,
                            author: result["author"].string!,
                            createdAt: OEXDateFormatting.dateWithServerString(result["created_at"].string!),
                            count: result["comment_count"].int!,
                            threadID: result["id"].string!)
                        
                        self.posts.append(item)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
                return Failure(nil)
        })
        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            println("\(result.data)")
        }
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
        if posts[indexPath.row].cellType == cellTypeTitleAndBy {
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
        return posts.count
    }
    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        let style = cellTextStyle.withSize(.Small)
        return text.map {text in
            return NSAttributedString.joinInNaturalLayout(
                before: icon.attributedTextWithStyle(style),
                after: style.attributedStringWithText(text))
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if posts[indexPath.row].cellType == cellTypeTitleAndBy {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleAndByCell, forIndexPath: indexPath) as! PostTitleByTableViewCell
            
            cell.typeText = Icon.Comments.attributedTextWithStyle(cellTextStyle)
            cell.titleText = posts[indexPath.row].title

            cell.byText = styledCellTextWithIcon(.User, text: posts[indexPath.row].author)
            cell.postCount = posts[indexPath.row].count
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleOnlyCell, forIndexPath: indexPath) as! PostTitleTableViewCell
            
            cell.typeText = Icon.Comments.attributedTextWithStyle(cellTextStyle)
            cell.titleText = posts[indexPath.row].title
            cell.postCount = posts[indexPath.row].count
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        environment.router?.showDiscussionResponsesFromViewController(self, item: posts[indexPath.row])
    }
}



