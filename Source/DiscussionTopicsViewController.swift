//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class DiscussionTopicsViewController: OfflineSupportViewController, UITableViewDataSource, UITableViewDelegate, InterfaceOrientationOverriding, LoadStateViewReloadSupport  {
    
    public typealias Environment = DataManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & ReachabilityProvider & NetworkManagerProvider
    
    fileprivate enum TableSection : Int {
        case AllPosts
        case Following
        case CourseTopics
    }
    
    fileprivate let topics = BackedStream<[DiscussionTopic]>()
    private let environment: Environment
    private let courseID : String
    
    private let searchBar = UISearchBar()
    private var searchBarDelegate : DiscussionSearchBarDelegate?
    private let loadController : LoadStateViewController
    
    private let contentView = UIView()
    private let tableView = UITableView()
    private let searchBarSeparator = UIView()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.loadController = LoadStateViewController()
        
        super.init(env: environment, shouldShowOfflineSnackBar: false)
       
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID: courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics(topics: $0)
            }
        )
        
        tableView.estimatedRowHeight = 80.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = Strings.discussionTopics
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        searchBarSeparator.backgroundColor = OEXStyles.shared().neutralLight()
        
        self.view.addSubview(contentView)
        self.contentView.addSubview(tableView)
        self.contentView.addSubview(searchBar)
        self.contentView.addSubview(searchBarSeparator)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        searchBar.applyStandardStyles(withPlaceholder: Strings.searchAllPosts)
        
        searchBarDelegate = DiscussionSearchBarDelegate() { [weak self] text in
            if let owner = self {
                owner.environment.router?.showPostsFromController(controller: owner, courseID: owner.courseID, queryString : text)
            }
        }
        
        searchBar.delegate = searchBarDelegate
        
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        searchBar.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(searchBarSeparator.snp_top)
        }
        
        searchBarSeparator.snp_makeConstraints { (make) -> Void in
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(tableView.snp_top)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(contentView)
        }
        
        // Register tableViewCell
        tableView.register(DiscussionTopicCell.classForCoder(), forCellReuseIdentifier: DiscussionTopicCell.identifier)
        
        loadController.setupInController(controller: self, contentView: contentView)
        loadTopics()
    }
    
    private func loadTopics() {
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            })
    }
    
    private func refreshTopics() {
        loadController.state = .Initial
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID: courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics(topics: $0)
            }
        )
        loadTopics()
    }
    
    func loadedData() {
        self.loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .NoTopics, message : Strings.unableToLoadCourseContent) : .Loaded
        self.tableView.reloadData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
        
        self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenViewTopics, courseID: self.courseID, value: nil)
        refreshTopics()
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func reloadViewData() {
        refreshTopics()
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        refreshTopics()
    }
    
    // MARK: - TableView Data and Delegate
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
        case TableSection.AllPosts.rawValue:
            return 1
        case TableSection.Following.rawValue:
            return 1
        case TableSection.CourseTopics.rawValue:
            return self.topics.value?.count ?? 0
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionTopicCell.identifier, for: indexPath) as! DiscussionTopicCell
        
        var topic : DiscussionTopic? = nil
        
        switch (indexPath.section) {
        case TableSection.AllPosts.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.allPosts, children: [DiscussionTopic](), depth: 0, icon:nil)
        case TableSection.Following.rawValue:
            topic = DiscussionTopic(id: nil, name: Strings.postsImFollowing, children: [DiscussionTopic](), depth: 0, icon: Icon.FollowStar)
        case TableSection.CourseTopics.rawValue:
            if let discussionTopic = self.topics.value?[indexPath.row] {
                topic = discussionTopic
            }
        default:
            assert(true, "Unknown section type.")
        }
        
        if let discussionTopic = topic {
            cell.topic = discussionTopic
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
        switch (indexPath.section) {
        case TableSection.AllPosts.rawValue:
            environment.router?.showAllPostsFromController(controller: self, courseID: courseID, followedOnly: false)
        case TableSection.Following.rawValue:
            environment.router?.showAllPostsFromController(controller: self, courseID: courseID, followedOnly: true)
        case TableSection.CourseTopics.rawValue:
            if let topic = self.topics.value?[indexPath.row] {
                environment.router?.showPostsFromController(controller: self, courseID: courseID, topic: topic)
            }
        default: ()
        }
        
        
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
}

extension DiscussionTopicsViewController {
    public func t_topicsLoaded() -> OEXStream<[DiscussionTopic]> {
        return topics
    }
}
