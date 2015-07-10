//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

enum CellType {
    case TitleAndBy, TitleOnly
}

struct DiscussionPostItem {
    let cellType: CellType
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
    
    private let postsButton = UIButton.buttonWithType(.System) as! UIButton
    private let activityButton = UIButton.buttonWithType(.System) as! UIButton
    private let newPostButton = UIButton.buttonWithType(.System) as! UIButton
    let course: OEXCourse
    
    var viewOption: UIView!
    var viewControllerOption: MenuOptionsViewController!
    let sortByOptions = [OEXLocalizedString("RECENT_ACTIVITY", nil) as String, OEXLocalizedString("MOST_ACTIVITY", nil) as String, OEXLocalizedString("MOST_VOTES", nil) as String]
    let filteringOptions = [OEXLocalizedString("ALL_POSTS", nil) as String, OEXLocalizedString("UNREAD", nil) as String, OEXLocalizedString("UNANSWERED", nil) as String]
    
    var isFilteringOptionsShowing: Bool?
    
    var posts: [DiscussionPostItem] = []
    let selectedTopic: Topic
    let searchResults: [DiscussionThread]?
    let topics: [Topic]
    let topicsArray: [String]
    
    
    init(env: PostsViewControllerEnvironment, course: OEXCourse, selectedTopic: Topic, searchResults: [DiscussionThread]?, topics: [Topic], topicsArray: [String]) {
        self.environment = env
        self.course = course
        self.selectedTopic = selectedTopic
        self.topics = topics
        self.topicsArray = topicsArray
        self.searchResults = searchResults
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        postsButton.setTitle(OEXLocalizedString("ALL_POSTS", nil), forState: .Normal)
        postsButton.addTarget(self,
            action: "postsTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(postsButton)
        
        postsButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view).offset(20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(searchResults==nil ? 20 : 0)
            make.width.equalTo(103)
        }
        
        activityButton.setTitle(OEXLocalizedString("RECENT_ACTIVITY", nil), forState: .Normal)
        activityButton.addTarget(self,
            action: "activityTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(activityButton)
        
        activityButton.snp_makeConstraints{ (make) -> Void in
            make.trailing.equalTo(view).offset(-20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(searchResults==nil ? 20 : 0)
            make.width.equalTo(103)
        }
        
        newPostButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()
        
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            after: style.attributedStringWithText(OEXLocalizedString("CREATE_A_NEW_POST", nil)))
        newPostButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        newPostButton.contentVerticalAlignment = .Center

        newPostButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            if let owner = self {
                owner.environment.router?.showDiscussionNewPostFromController(owner)
            }
        }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(newPostButton)
        newPostButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(searchResults==nil ? 60 : 0)
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
        
        if searchResults == nil {
            
            tableView.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(view)
                make.top.equalTo(postsButton).offset(30)
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
                make.top.equalTo(postsButton.snp_bottom).offset(searchResults==nil ? 12 : 0)
            }
        }
        else {
            tableView.snp_makeConstraints { (make) -> Void in
                make.leading.equalTo(view)
                make.top.equalTo(view)
                make.trailing.equalTo(view)
                make.bottom.equalTo(newPostButton.snp_top)
            }
        }
        
        if let threads = searchResults {
            self.navigationItem.title = OEXLocalizedString("SEARCH_RESULTS", nil)
        }
        else {
            self.navigationItem.title = selectedTopic.name
        }        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let threads = searchResults {
            // TODO: hide "Create a new post" button and "All Posts" and "Recent Activity" filter buttons
            
            
            self.posts.removeAll(keepCapacity: true)
            
            for discussionThread in threads {
                if let rawBody = discussionThread.rawBody,
                    let author = discussionThread.author,
                    let createdAt = discussionThread.createdAt,
                    let title = discussionThread.title,
                    let threadID = discussionThread.identifier {
                        let item = DiscussionPostItem(cellType: CellType.TitleAndBy,
                            title: title,
                            body: rawBody,
                            author: author,
                            createdAt: createdAt,
                            count: discussionThread.commentCount,
                            threadID: threadID)
                        self.posts.append(item)
                }
            }
            
            self.tableView.reloadData()
        }
        else {
            let apiRequest = DiscussionAPI.getThreads(self.course.course_id!)
            
            environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let threads: [DiscussionThread] = result.data {
                    self.posts.removeAll(keepCapacity: true)
                    
                    for discussionThread in threads {
                        if let rawBody = discussionThread.rawBody,
                            let author = discussionThread.author,
                            let createdAt = discussionThread.createdAt,
                            let title = discussionThread.title,
                            let threadID = discussionThread.identifier {
                                let item = DiscussionPostItem(cellType: CellType.TitleAndBy,
                                    title: title,
                                    body: rawBody,
                                    author: author,
                                    createdAt: createdAt,
                                    count: discussionThread.commentCount,
                                    threadID: threadID)
                                self.posts.append(item)
                        }
                    }
                }
                
                self.tableView.reloadData()
            }
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
            postsButton.setTitle(filteringOptions[selectedRow], forState: .Normal)
        }
        else {
            activityButton.setTitle(sortByOptions[selectedRow], forState: .Normal)
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
        if posts[indexPath.row].cellType == .TitleAndBy {
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
        if posts[indexPath.row].cellType == .TitleAndBy {
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



