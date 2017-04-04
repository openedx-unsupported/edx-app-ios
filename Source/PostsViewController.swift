//
//  PostsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class PostsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, PullRefreshControllerDelegate, InterfaceOrientationOverriding, DiscussionNewPostViewControllerDelegate {

    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider, OEXStylesProvider>
    
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
    var environment: Environment!
    private var paginationController : PaginationController<DiscussionThread>?
    
    private lazy var tableView = UITableView(frame: CGRectZero, style: .Plain)

    private let viewSeparator = UIView()
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    
    private let refineLabel = UILabel()
    private let headerButtonHolderView = UIView()
    private let headerView = UIView()
    private var searchBar : UISearchBar?
    private let filterButton = PressableCustomButton()
    private let sortButton = PressableCustomButton()
    private let newPostButton = UIButton(type: .System)
    private let courseID: String
    private var isDiscussionBlackedOut: Bool = true {
        didSet {
            updateNewPostButtonStyle()
        }
    }
    private var stream: Stream<(DiscussionInfo)>?
    
    private let contentView = UIView()
    
    private var context : Context?
    private let topicID: String?
    
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
    
    required init(environment: Environment, courseID: String, topicID: String?, context: Context?) {
        self.courseID = courseID
        self.environment = environment
        self.topicID = topicID
        self.context = context
        super.init(nibName: nil, bundle: nil)
        
        configureSearchBar()
    }
    
    convenience init(environment: Environment, courseID: String, topicID: String?) {
        self.init(environment: environment, courseID : courseID, topicID: topicID, context: nil)
    }
    
    convenience init(environment: Environment, courseID: String, topic: DiscussionTopic) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context: .Topic(topic))
    }
    
    convenience init(environment: Environment,courseID: String, queryString : String) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context : .Search(queryString))
    }
    
    ///Convenience initializer for All Posts and Followed posts
    convenience init(environment: Environment, courseID: String, following : Bool) {
        self.init(environment: environment, courseID : courseID, topicID: nil, context : following ? .Following : .AllPosts)
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
        tableView.applyStandardSeparatorInsets()
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
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
                    owner.environment.router?.showDiscussionNewPostFromController(owner, courseID: owner.courseID, selectedTopic : owner.context?.selectedTopic)
                }
            }, forEvents: .TouchUpInside)

        loadController.setupInController(self, contentView: contentView)
        insetsController.setupInController(self, scrollView: tableView)
        refreshController.setupInScrollView(tableView)
        insetsController.addSource(refreshController)
        refreshController.delegate = self
        
        //set visibility of header view
        updateHeaderViewVisibility()
        
        loadContent()
        
        setAccessibility()
    }
    
    private func setAccessibility() {
        if let searchBar = searchBar {
            view.accessibilityElements = [searchBar, tableView]
        }
        else {
            view.accessibilityElements = [refineLabel, filterButton, sortButton, tableView, newPostButton]
        }
        
        updateAccessibility()
    }
    
    private func updateAccessibility() {
        
        filterButton.accessibilityLabel = Strings.Accessibility.discussionFilterBy(filterBy: titleForFilter(selectedFilter))
        filterButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
        sortButton.accessibilityLabel = Strings.Accessibility.discussionSortBy(sortBy: titleForSort(selectedOrderBy))
        sortButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
    }
    
    private func configureSearchBar() {
        guard let context = context where !context.allowsPosting else {
            return
        }
        
        searchBar = UISearchBar()
        searchBar?.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
        searchBar?.text = context.queryString
        searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
            self?.context = Context.Search(text)
            self?.loadController.state = .Initial
            self?.searchThreads(text)
            self?.searchBar?.delegate = self?.searchBarDelegate
        }
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
        contentView.snp_remakeConstraints { (make) -> Void in
            if  context?.allowsPosting ?? false {
                make.top.equalTo(view)
            }
            //Else the top is equal to searchBar.snp_bottom
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            //The bottom is equal to newPostButton.snp_top
        }
        
        headerView.snp_remakeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(contentView)
            make.height.equalTo(context?.allowsPosting ?? false ? 40 : 0)
        }
        
        searchBar?.snp_remakeConstraints(closure: { (make) -> Void in
            make.top.equalTo(view)
            make.trailing.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.bottom.equalTo(contentView.snp_top)
        })
        
        refineLabel.snp_remakeConstraints { (make) -> Void in
            make.leadingMargin.equalTo(headerView).offset(StandardHorizontalMargin)
            make.centerY.equalTo(headerView)
        }
        refineLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        
        headerButtonHolderView.snp_remakeConstraints { (make) -> Void in
            make.leading.equalTo(refineLabel.snp_trailing)
            make.trailing.equalTo(headerView)
            make.bottom.equalTo(headerView)
            make.top.equalTo(headerView)
        }
        
        
        filterButton.snp_remakeConstraints{ (make) -> Void in
            make.leading.equalTo(headerButtonHolderView)
            make.trailing.equalTo(sortButton.snp_leading)
            make.centerY.equalTo(headerButtonHolderView)
        }
        
        sortButton.snp_remakeConstraints{ (make) -> Void in
            make.trailingMargin.equalTo(headerButtonHolderView)
            make.centerY.equalTo(headerButtonHolderView)
            make.width.equalTo(filterButton.snp_width)
        }
        newPostButton.snp_remakeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(context?.allowsPosting ?? false ? OEXStyles.sharedStyles().standardFooterHeight : 0)
            make.top.equalTo(contentView.snp_bottom)
            make.bottom.equalTo(view)
        }
        
        tableView.snp_remakeConstraints { (make) -> Void in
            make.leading.equalTo(contentView)
            make.top.equalTo(viewSeparator.snp_bottom)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(newPostButton.snp_top)
        }
        
        viewSeparator.snp_remakeConstraints{ (make) -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(OEXStyles.dividerSize())
            make.top.equalTo(headerView.snp_bottom)
        }
    }

    private func setStyles() {
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        
        self.refineLabel.attributedText = self.refineTextStyle.attributedStringWithText(Strings.refine)
        
        var buttonTitle = NSAttributedString.joinInNaturalLayout(
            [Icon.Filter.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
                filterTextStyle.attributedStringWithText(self.titleForFilter(self.selectedFilter))])
        filterButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Sort.attributedTextWithStyle(filterTextStyle.withSize(.XSmall)),
            filterTextStyle.attributedStringWithText(Strings.recentActivity)])
        sortButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        
        updateNewPostButtonStyle()
        
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: environment.styles.neutralWhite())
        buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            style.attributedStringWithText(Strings.createANewPost)])
        newPostButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        newPostButton.contentVerticalAlignment = .Center
        
        self.navigationItem.title = context?.navigationItemTitle
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        viewSeparator.backgroundColor = environment.styles.neutralXLight()
    }
    
    private func updateNewPostButtonStyle() {
        newPostButton.backgroundColor = isDiscussionBlackedOut ? environment.styles.neutralBase() : environment.styles.primaryXDarkColor()
        newPostButton.enabled = !isDiscussionBlackedOut
    }
    
    func setIsDiscussionBlackedOut(value : Bool){
        isDiscussionBlackedOut = value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndex = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndex, animated: false)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    private func logScreenEvent() {
        guard let context = context else {
            return
        }
        
        switch context {
        case let .Topic(topic):
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: topic.name, threadId: nil, topicId: topic.id, responseID: nil)
        case let .Search(query):
            self.environment.analytics.trackScreenWithName(OEXAnalyticsScreenSearchThreads, courseID: self.courseID, value: query, additionalInfo:["search_string":query])
        case .Following:
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: "posts_following", threadId: nil, topicId: "posts_following", responseID: nil)
        case .AllPosts:
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewTopicThreads, courseId: self.courseID, value: "all_posts", threadId: nil, topicId: "all_posts", responseID: nil)
        }
    }
    
    private func loadContent() {
        let apiRequest = DiscussionAPI.getDiscussionInfo(courseID)
        stream = environment.networkManager.streamForRequest(apiRequest)
        stream?.listen(self, success: { [weak self] (discussionInfo) in
            self?.isDiscussionBlackedOut = discussionInfo.isBlackedOut
            self?.loadPostContent()
            }
            ,failure: { [weak self] (error) in
                self?.loadController.state = LoadState.failed(error)
            })
    }
    
    private func loadPostContent() {
        guard let context = context else {
            // context is only nil in case if topic is selected
            loadTopic()
            return
        }
        
        logScreenEvent()
        
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
    
    private func loadTopic() {
        guard let topicID = topicID else {
            loadController.state = LoadState.failed(NSError.oex_unknownError())
            return
        }
        
        let apiRequest = DiscussionAPI.getTopicByID(courseID, topicID: topicID)
        self.environment.networkManager.taskForRequest(apiRequest) {[weak self] response in
            if let topics = response.data {
                //Sending signle topic id so always get a single topic
                self?.context = .Topic(topics[0])
                self?.navigationItem.title = self?.context?.navigationItemTitle
                self?.setConstraints()
                self?.loadContent()
            }
            else {
                self?.loadController.state = LoadState.failed(response.error)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    private func updateHeaderViewVisibility() {
        
        // if post has results then set hasResults yes
        hasResults = context?.allowsPosting ?? false && self.posts.count > 0
        
        headerView.hidden = !hasResults
    }
    
    private func loadFollowedPostsForFilter(filter : DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getFollowedThreads(courseID: self.courseID, filter: filter, orderBy: orderBy, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    private func searchThreads(query : String) {
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.searchThreads(courseID: self.courseID, searchText: query, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    private func loadPostsForTopic(topic : DiscussionTopic?, filter: DiscussionPostsFilter, orderBy: DiscussionPostsSort) {
       
        var topicIDApiRepresentation : [String]?
        if let identifier = topic?.id {
            topicIDApiRepresentation = [identifier]
        }
            //Children's topic IDs if the topic is root node
        else if let discussionTopic = topic {
            topicIDApiRepresentation = discussionTopic.children.mapSkippingNils { $0.id }
        }
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getThreads(courseID: self.courseID, topicIDs: topicIDApiRepresentation, filter: filter, orderBy: orderBy, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        loadThreads()
    }
    
    
    private func loadThreads() {
        paginationController?.stream.listen(self, success:
            { [weak self] threads in
                self?.posts.removeAll()
                self?.updatePostsFromThreads(threads)
                self?.refreshController.endRefreshing()
            }, failure: { [weak self] (error) -> Void in
                self?.loadController.state = LoadState.failed(error)
            })
        
        paginationController?.loadMore()
    }
    
    private func updatePostsFromThreads(threads : [DiscussionThread]) {
        
        for thread in threads {
            self.posts.append(thread)
        }
        self.tableView.reloadData()
        let emptyState = LoadState.empty(icon : nil , message: errorMessage())
        
        self.loadController.state = self.posts.isEmpty ? emptyState : .Loaded
        // set visibility of header view
        updateHeaderViewVisibility()
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
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
        guard let context = context else {
            return ""
        }
        
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
            self.loadController.state = .Initial
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Filter.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForFilter(filter))])
            
            self.filterButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
            self.updateAccessibility()
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
            self.loadController.state = .Initial
            self.loadContent()
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([Icon.Sort.attributedTextWithStyle(self.filterTextStyle.withSize(.XSmall)),
                self.filterTextStyle.attributedStringWithText(self.titleForSort(sort))])
            
            self.sortButton.setAttributedTitle(buttonTitle, forState: .Normal, animated: false)
            self.updateAccessibility()
        }
        
        controller.addCancelAction()
        self.presentViewController(controller, animated: true, completion:nil)
    }
    
    private func updateSelectedPostAttributes(indexPath: NSIndexPath) {
        posts[indexPath.row].read = true
        posts[indexPath.row].unreadCommentCount = 0
        tableView.reloadData()
    }
    
    //MARK :- DiscussionNewPostViewControllerDelegate method
    
    func newPostController(controller: DiscussionNewPostViewController, addedPost post: DiscussionThread) {
        loadContent()
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
    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    var unreadIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Large, color: OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    var readIconTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBase())
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
        updateSelectedPostAttributes(indexPath)
        environment.router?.showDiscussionResponsesFromViewController(self, courseID : courseID, threadID: posts[indexPath.row].threadID, isDiscussionBlackedOut: isDiscussionBlackedOut)
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

// Testing only
extension PostsViewController {
    
    var t_loaded : Stream<()> {
        return self.stream!.map {_ in () }
    }
    
    var t_loaded_pagination : Stream<()> {
        return self.paginationController!.stream.map {_ in
            return
        }
    }
}

