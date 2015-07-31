//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class DiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {
    
    class Environment {
        private let config: OEXConfig?
        private let courseDataManager : CourseDataManager
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        
        init(config: OEXConfig,
            courseDataManager : CourseDataManager,
            networkManager: NetworkManager,
            router: OEXRouter)
        {
            self.config = config
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
        }
    }
    
    private let topics = BackedStream<[DiscussionTopic]>()
    private let environment: Environment
    private let courseID : String
    
    private let searchBar = UISearchBar()
    
    private var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBlack())
    }
    
    private let tableView = UITableView()
    
    init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: nil, bundle: nil)
        
        let stream = environment.courseDataManager.discussionTopicManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
    }
    
    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.navigationItem.title = OEXLocalizedString("DISCUSSION_TOPICS", nil)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: OEXLocalizedString("TOPICS", nil), style: .Plain, target: nil, action: nil)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        searchBar.placeholder = OEXLocalizedString("SEARCH_ALL_POSTS", nil)
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        
        self.view.addSubview(searchBar)
        
        searchBar.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBar.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicsCell.self, forCellReuseIdentifier: DiscussionTopicsCell.identifier)
        
        topics.listen(self) {[weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            return
        }
        
        let apiRequest = DiscussionAPI.searchThreads(courseID: self.courseID, searchText: searchBar.text)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            if let threads: [DiscussionThread] = result.data, owner = self {
                owner.environment.router?.showPostsFromController(owner, courseID: owner.courseID, searchResults: threads)
            }
        }
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    
    // MARK: - TableView Data and Delegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topics.value?.count ?? 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionTopicsCell.identifier, forIndexPath: indexPath) as! DiscussionTopicsCell
        
        if let topic = self.topics.value?[indexPath.row] {
            cell.topic = topic
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        if let topic = self.topics.value?[indexPath.row] {
            environment.router?.showPostsFromController(self, courseID: courseID, topic: topic)
        }
    }

}
