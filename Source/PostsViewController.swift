//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class PostsViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    let networkManager : NetworkManager?
    let styles : OEXStyles
    
    init(networkManager : NetworkManager?, router: OEXRouter?, styles : OEXStyles = OEXStyles.sharedStyles()) {
        self.networkManager = networkManager
        self.router = router
        self.styles = styles
    }
}

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PullRefreshControllerDelegate {

    enum Context {
        case Topic(DiscussionTopic)
        case Following
        case Search(String)
        case AllPosts
        
        var allowsPosting : Bool {
            switch self {
            case Topic: return true
            case Following: return true
            case Search: return false
            case AllPosts: return true
            }
        }
        
        var topic : DiscussionTopic? {
            switch self {
            case let Topic(topic): return topic
            case Search(_): return nil
            case Following(_): return nil
            case AllPosts(_): return nil
            }
        }
        
        var navigationItemTitle : String? {
            switch self {
            case let Topic(topic): return topic.name
            case Search(_): return Strings.searchResults
            case Following(_): return Strings.postsImFollowing
            case AllPosts(_): return Strings.allPosts
            }
        }

        //Strictly to be used to pass on to DiscussionNewPostViewController.
        var selectedTopic : DiscussionTopic? {
            switch self {
            case let Topic(topic): return topic.isSelectable ? topic : topic.firstSelectableChild()
            case Search(_): return nil
            case Following(_): return nil
            case AllPosts(_): return nil
            }
        }
        
        var noResultsMessage : String {
            switch self {
            case Topic(_): return Strings.noResultsFound
            case AllPosts: return Strings.noCourseResults
            case Following: return Strings.noFollowingResults
            case let .Search(string) : return Strings.emptyResultset(queryString: string)
            }
        }
        
        private var queryString: String? {
            switch self {
            case Topic(_): return nil
            case AllPosts: return nil
            case Following: return nil
            case let .Search(string) : return string
            }
        }
        
    }
    
    let environment: PostsViewControllerEnvironment
    var networkPaginator : NetworkPaginator<DiscussionThread>?
    
    private lazy var tableView = UITableView(frame: CGRectZero, style: .Plain)

    private let viewSeparator = UIView()
    private let loadController : LoadStateViewController
    private let refreshController : PullRefreshController
    private let insetsController = ContentInsetsController()
    
    private let refineLabel = UILabel()
    private let headerButtonHolderView = UIView()
    private let headerView = UIView()
    private var searchBar : UISearchBar?
    private let filterButton = PressableCustomButton()
    private let sortButton = PressableCustomButton()
    private let newPostButton = UIButton(type: .System)
    private let courseID: String
    
    private let contentView = UIView()
    
    private var context : Context
    
    private var posts: [DiscussionThread] = []
    private var selectedFilter: DiscussionPostsFilter = .AllPosts
    private var selectedOrderBy: DiscussionPostsSort = .RecentActivity
    
    var searchBarDelegate : DiscussionSearchBarDelegate?
    
    private var queryString : String?
    private var refineTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }

    private var filterTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Small, color: OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    private var hasResults:Bool = false
    
    required init(environment : PostsViewControllerEnvironment, courseID : String, context : Context) {
        self.environment = environment
        self.courseID = courseID
        self.context = context
        loadController = LoadStateViewController()
        refreshController = PullRefreshController()
        
        super.init(nibName: nil, bundle: nil)
        
        if !self.context.allowsPosting {
            searchBar = UISearchBar()
            searchBar?.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
            searchBar?.text = context.queryString
            searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
                self?.context = Context.Search(text)
                self?.loadController.state = .Initial
                self?.loadContent()
            }
            searchBar?.delegate = searchBarDelegate
        }
    }
    
    convenience init(environment: PostsViewControllerEnvironment, courseID: String, topic : DiscussionTopic) {
        self.init(environment : environment, courseID : courseID, context : .Topic(topic))
    }
    
    convenience init(environment: PostsViewControllerEnvironment, courseID: String, queryString : String) {
        self.init(environment : environment, courseID : courseID, context : .Search(queryString))
    }
    
    ///Convenience initializer for All Posts and Followed posts
    convenience init(environment: PostsViewControllerEnvironment, courseID: String, following : Bool) {
        self.init(environment : environment, courseID : courseID, context : following ? .Following : .AllPosts)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        setConstraints()
        setStyles()
        
        tableView.registerClass(PostTableViewCell.classForCoder(), forCellReuseIdentifier: PostTableViewCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        
        filterButton.oex_addAction(
            {[weak self] _ in
                self?.showFilterPicker()
            }, forEvents: .TouchUpInside)
        sortButton.oex_addAction(
            {[weak self] _ in
                self?.showSortPicker()
            }, forEvents: .TouchUpInside)
        newPostButton.oex_addAction(
            {[weak self] _ in
                if let owner = self {
                    owner.environment.router?.showDiscussionNewPostFromController(owner, courseID: owner.courseID, selectedTopic : owner.context.selectedTopic)
                }
            }, forEvents: .TouchUpInside)

        loadController.setupInController(self, contentView: contentView)
        insetsController.setupInController(self, scrollView: tableView)
        refreshController.setupInScrollView(tableView)
        insetsController.addSource(refreshController)
        refreshController.delegate = self
        
        //set visibility of header view
        updateHeaderViewVisibility()
    }
    
    private func addSubviews() {
        view.addSubview(contentView)
        view.addSubview(headerView)
        if let searchBar = searchBar {
            view.addSubview(searchBar)
        }
        contentView.addSubview(tableView)
        headerView.addSubview(refineLabel)
        headerView.addSubview(headerButtonHolderView)
        headerButtonHolderView.addSubview(filterButton)
        headerButtonHolderView.addSubview(sortButton)
        view.addSubview(newPostButton)
        contentView.addSubview(viewSeparator)
    }
    
    private func setConstraints() {
        contentView.snp_makeConstraints { (make) -> Void in
            if context.allowsPosting {
                make.top.equalTo(view)
            }
            //Else the top is equal to searchBar.snp_bottom
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            //The bottom is equal to newPostButton.snp_top
        }
        
        headerView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView)
            make.height.equalTo(context.allowsPosting ? 40 : 0)
        }
        
        searchBar?.snp_makeConstraints(closure: { (make) -> Void in
            make.top.equalTo(view)
            make.trailing.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.bottom.equalTo(contentView.snp_top)
        })
        
        refineLabel.snp_makeConstraints { (make) -> Void in
            make.leadingMargin.equalTo(headerView).offset(StandardHorizontalMargin)
            make.centerY.equalTo(headerView)
        }
        refineLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        
        
        headerButtonHolderView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(refineLabel.snp_trailing)
            make.trailing.equalTo(headerView)
            make.bottom.equalTo(headerView)
            make.top.equalTo(headerView)
        }
        
        
        filterButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(headerButtonHolderView)
            make.trailing.equalTo(sortButton.snp_leading)
            make.centerY.equalTo(headerButtonHolderView)
        }
        
        sortButton.snp_makeConstraints{ (make) -> Void in
            make.trailingMargin.equalTo(headerButtonHolderView)
            make.centerY.equalTo(headerButtonHolderView)
            make.width.equalTo(filterButton.snp_width)
        }
        newPostButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(context.allowsPosting ? OEXStyles.sharedStyles().standardFooterHeight : 0)
            make.top.equalTo(contentView.snp_bottom)
            make.bottom.equalTo(view)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.top.equalTo(viewSeparator.snp_bottom)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(newPostButton.snp_top)
        }
        
        viewSeparator.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(OEXStyles.dividerSize())
            make.top.equalTo(headerView.snp_bottom)
        }
    }

    private func setStyles() {
        view.backgroundColor = self.environment.styles.standardBackgroundColor()
        
        self.refineLabel.attributedText = self.refineTextStyle.attributedStringWithText(Strings.refine)
        
        var buttonTitle = NSAttributedString.joinInNaturalLayout(
            [Icon.Filter.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
                filterTextStyle.attributedStringWithText(self.titleForFilter(self.selectedFilter))])
        filterButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Sort.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
            filterTextStyle.attributedStringWithText(Strings.recentActivity)])
        sortButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        
        newPostButton.backgroundColor = self.environment.styles.primaryXDarkColor()
        
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: self.environment.styles.neutralWhite())
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            style.attributedStringWithText(Strings.createANewPost)])
        newPostButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        newPostButton.contentVerticalAlignment = .Center
        
        self.navigationItem.title = context.navigationItemTitle
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        viewSeparator.backgroundColor = self.environment.styles.neutralXLight()
        
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndex = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndex, animated: false)
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadContent()
    }
    
    private func loadContent() {
        switch context {
        case let .Topic(topic):
            loadPostsForTopic(topic, filter: selectedFilter, orderBy: selectedOrderBy)
        case let .Search(query):
            searchThreads(query)
        case .Following:
            loadFollowedPostsForFilter(selectedFilter, orderBy: selectedOrderBy)
        case .AllPosts:
            loadPostsForTopic(nil, filter: selectedFilter, orderBy: selectedOrderBy)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    private func updateHeaderViewVisibility() {
        
        // if post has results then set hasResults yes
        if context.allowsPosting && self.posts.count > 0 {
                hasResults = true
        }
        
        headerView.hidden = !hasResults
    }
    
    private func loadFollowedPostsForFilter(filter : DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
        
        let followedFeed = PaginatedFeed() { i in
            return DiscussionAPI.getFollowedThreads(courseID: self.courseID, filter: filter, orderBy: orderBy, pageNumber: i)
        }
        loadThreadsFromPaginatedFeed(followedFeed)
    }
    
    private func loadThreadsFromPaginatedFeed(feed : PaginatedFeed<NetworkRequest<[DiscussionThread]>>) {
        
        self.networkPaginator = NetworkPaginator(networkManager: self.environment.networkManager, paginatedFeed: feed, tableView : self.tableView)
        
        self.networkPaginator?.loadDataIfAvailable() {[weak self] results in
            self?.refreshController.endRefreshing()
            self?.loadController.handleErrorForPaginatedArray(self?.posts, error: results?.error)
            if let threads = results?.data {
                self?.updatePostsFromThreads(threads, removeAll: true)
            }
        }
    }
    
    
    private func searchThreads(query : String) {
        let threadsFeed = PaginatedFeed() { i in
            DiscussionAPI.searchThreads(courseID: self.courseID, searchText: query, pageNumber: i)
        }
        self.loadThreadsFromPaginatedFeed(threadsFeed)
    }
    
    private func loadPostsForTopic(topic : DiscussionTopic?, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
        let threadsFeed : PaginatedFeed<NetworkRequest<[DiscussionThread]>>
        threadsFeed = PaginatedFeed() { i in
            //Topic ID if topic isn't root node
            var topicIDApiRepresentation : [String]?
            if let identifier = topic?.id {
                topicIDApiRepresentation = [identifier]
            }
            //Children's topic IDs if the topic is root node
            else if let discussionTopic = topic {
                topicIDApiRepresentation = discussionTopic.children.mapSkippingNils { $0.id }
            }
            //topicIDApiRepresentation = nil when fetching all posts for a course
        return DiscussionAPI.getThreads(courseID: self.courseID, topicIDs: topicIDApiRepresentation, filter: filter, orderBy: orderBy, pageNumber: i)
        }
        loadThreadsFromPaginatedFeed(threadsFeed)
    }
    
    private func updatePostsFromThreads(threads : [DiscussionThread], removeAll : Bool) {
        if (removeAll) {
            self.posts.removeAll(keepCapacity: true)
        }
        
        for thread in threads {
            self.posts.append(thread)
        }
        self.tableView.reloadData()
        let emptyState = LoadState.empty(icon : nil , message: errorMessage())
        
        self.loadController.state = self.posts.isEmpty ? emptyState : .Loaded
        // set visibility of header view
        updateHeaderViewVisibility()
    }

    func titleForFilter(filter : DiscussionPostsFilter) -> String {
        switch filter {
        case .AllPosts: return Strings.allPosts
        case .Unread: return Strings.unread
        case .Unanswered: return Strings.unanswered
        }
    }
    
    func titleForSort(filter : DiscussionPostsSort) -> String {
        switch filter {
        case .RecentActivity: return Strings.recentActivity
        case .MostActivity: return Strings.mostActivity
        case .VoteCount: return Strings.mostVotes
        }
    }
    
    func isFilterApplied() -> Bool {
            switch self.selectedFilter {
            case .AllPosts: return false
            case .Unread: return true
            case .Unanswered: return true
        }
    }
    
    func errorMessage() -> String {
        if isFilterApplied() {
            return context.noResultsMessage + " " + Strings.removeFilter
        }
        else {
            return context.noResultsMessage
        }
    }
    
    func showFilterPicker() {
        let options = [.AllPosts, .Unread, .Unanswered].map {
            return (title : self.titleForFilter($0), value : $0)
        }

        let controller = UIAlertController.actionSheetWithItems(options, currentSelection : self.selectedFilter) {filter in
            self.selectedFilter = filter
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Filter.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForFilter(filter))])
            
            self.filterButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        }
        controller.addCancelAction()
        self.presentViewController(controller, animated: true, completion:nil)
    }
    
    func showSortPicker() {
        let options = [.RecentActivity, .MostActivity, .VoteCount].map {
            return (title : self.titleForSort($0), value : $0)
        }
        
        let controller = UIAlertController.actionSheetWithItems(options, currentSelection : self.selectedOrderBy) {sort in
            self.selectedOrderBy = sort
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Sort.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForSort(sort))])
            
            self.sortButton.setAttributedTitle(buttonTitle, forState: .Normal, animated: false)
        }
        
        controller.addCancelAction()
        self.presentViewController(controller, animated: true, completion:nil)
    }
    
    // MARK - Pull Refresh
    
    func refreshControllerActivated(controller: PullRefreshController) {
        loadContent()
    }
    
    // MARK - Table View Delegate
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let paginator = self.networkPaginator where tableView.isLastRow(indexPath : indexPath) {
            paginator.loadDataIfAvailable() {[weak self] results in
                self?.loadController.handleErrorForPaginatedArray(self?.posts, error: results?.error)
                if let threads = results?.data {
                    self?.updatePostsFromThreads(threads, removeAll: false)
                }
            }
        }
    }

    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: self.environment.styles.primaryBaseColor())
    }
    
    var unreadIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Large, color: self.environment.styles.primaryBaseColor())
    }
    
    var readIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: self.environment.styles.neutralBase())
    }
    
    func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        let style = cellTextStyle.withSize(.Small)
        return text.map {text in
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedStringWithText(text)])
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PostTableViewCell.identifier, forIndexPath: indexPath) as! PostTableViewCell
        cell.useThread(posts[indexPath.row], selectedOrderBy : selectedOrderBy)
        cell.applyStandardSeparatorInsets()
            return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        environment.router?.showDiscussionResponsesFromViewController(self, courseID : courseID, threadID: posts[indexPath.row].threadID)
    }
}

//We want to make sure that only non-root node topics are selectable
public extension DiscussionTopic {
    var isSelectable : Bool {
        return self.depth != 0 || self.id != nil
    }
    
    func firstSelectableChild(forTopic topic : DiscussionTopic? = nil) -> DiscussionTopic? {
        let discussionTopic = topic ?? self
        if let matchedIndex = discussionTopic.children.firstIndexMatching({$0.isSelectable }) {
            return discussionTopic.children[matchedIndex]
        }
        if discussionTopic.children.count > 0 {
            return firstSelectableChild(forTopic : discussionTopic.children[0])
        }
        return nil
    }
}

extension UITableView {
    //Might be worth adding a section argument in the future
    func isLastRow(indexPath indexPath : NSIndexPath) -> Bool {
        return indexPath.row == self.numberOfRowsInSection(indexPath.section) - 1 && indexPath.section == self.numberOfSections - 1
    }
}


