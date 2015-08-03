//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class DiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {
    
    public class Environment {
        private let config: OEXConfig?
        private let courseDataManager : CourseDataManager
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        private let styles : OEXStyles
        
        public init(config: OEXConfig,
            courseDataManager : CourseDataManager,
            networkManager: NetworkManager?,
            router: OEXRouter?,
            styles: OEXStyles)
        {
            self.config = config
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
            self.styles = styles
        }
    }
    
    private let topics = BackedStream<[DiscussionTopic]>()
    private let environment: Environment
    private let courseID : String
    
    private let searchBar = UISearchBar()
    private let loadController : LoadStateViewController
    
    private var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: self.environment.styles.neutralBlack())
    }
    
    private let contentView = UIView()
    private let tableView = UITableView()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        self.loadController = LoadStateViewController(styles : environment.styles)
        
        super.init(nibName: nil, bundle: nil)
        
        let stream = environment.courseDataManager.discussionTopicManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
    }
    
    public required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = OEXLocalizedString("DISCUSSION_TOPICS", nil)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: OEXLocalizedString("TOPICS", nil), style: .Plain, target: nil, action: nil)
        
        view.backgroundColor = self.environment.styles.standardBackgroundColor()
        self.view.addSubview(contentView)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.applyStandardSeparatorInsets()
        self.contentView.addSubview(tableView)
        
        searchBar.placeholder = OEXLocalizedString("SEARCH_ALL_POSTS", nil)
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.searchBarStyle = .Minimal
        searchBar.sizeToFit()
        
        tableView.tableHeaderView = searchBar
        
        contentView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.edges.equalTo(self.contentView)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicsCell.self, forCellReuseIdentifier: DiscussionTopicsCell.identifier)
        
        loadController.setupInController(self, contentView: contentView)
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
        }, failure : {[weak self] error in
            self?.loadController.state = LoadState.failed(error: error)
        })
    }
    
    func loadedData() {
        self.loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .NoTopics, message : OEXLocalizedString("UNABLE_TO_LOAD_COURSE_CONTENT", nil)) : .Loaded
        self.tableView.reloadData()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    public func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
            return
        }
        
        // TODO: Move this inside the search screen and add a failure + empty cases
        let apiRequest = DiscussionAPI.searchThreads(courseID: self.courseID, searchText: searchBar.text)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            if let threads: [DiscussionThread] = result.data, owner = self {
                owner.environment.router?.showPostsFromController(owner, courseID: owner.courseID, searchResults: threads)
            }
        }
    }
    
    public func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    
    public func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    // MARK: - TableView Data and Delegate
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topics.value?.count ?? 0
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionTopicsCell.identifier, forIndexPath: indexPath) as! DiscussionTopicsCell
        
        if let topic = self.topics.value?[indexPath.row] {
            cell.topic = topic
        }
        
        return cell
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        if let topic = self.topics.value?[indexPath.row] {
            environment.router?.showPostsFromController(self, courseID: courseID, topic: topic)
        }
    }

}


extension DiscussionTopicsViewController {
    public func t_topicsLoaded() -> Stream<[DiscussionTopic]> {
        return topics
    }
}