//
//  DiscussionTopicsViewController.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class DiscussionTopicsViewControllerEnvironment : NSObject {
    let config: OEXConfig?
    weak var router: OEXRouter?
    let networkManager: NetworkManager?
    
    init(config: OEXConfig, networkManager: NetworkManager, router: OEXRouter) {
        self.config = config
        self.networkManager = networkManager
        self.router = router
    }
}

class DiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate  {

    private let environment: DiscussionTopicsViewControllerEnvironment
    let course: OEXCourse
    
    private var searchBar: UISearchBar = UISearchBar()
    
    // TODO: adjust each value once the final UI is out
    let TEXT_MARGIN = 10.0
    let TABLEVIEW_LEADING_MARGIN = 30.0
    
    var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBlack())
    }
    
    private var tableView: UITableView = UITableView()
    private var selectedIndexPath: NSIndexPath?
    
    var topicsArray: [String] = []
    var topics: [Topic] = []
    var selectedTopic: Topic?
    
    var searchText: String?
    var searchResults: [DiscussionThread]?
    
    init(environment: DiscussionTopicsViewControllerEnvironment, course: OEXCourse) {
        self.environment = environment
        self.course = course
        
        super.init(nibName: nil, bundle: nil)
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
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        searchBar.placeholder = OEXLocalizedString("SEARCH_ALL_POSTS", nil)
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        
        self.view.addSubview(searchBar)
        
        searchBar.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.view).offset(-TABLEVIEW_LEADING_MARGIN)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBar.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicsCell.self, forCellReuseIdentifier: DiscussionTopicsCell.identifier)
        
        let apiRequest = DiscussionAPI.getCourseTopics(self.course.course_id!)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            if let topics = result.data {
                self?.topics = topics
                for topic in topics {
                    if let name = topic.name {
                        self?.topicsArray.append(name)
                        for child in topic.children ?? [] {
                            if let childName = child.name {
                                self?.topicsArray.append("     \(childName)")
                            }
                        }
                    }
                }
            }
            
            self?.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedIndexPath {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) == "" {
            searchResults = nil
            return
        }
        
        if let courseID = self.course.course_id {
            let apiRequest = DiscussionAPI.searchThreads(courseID: courseID, searchText: searchBar.text)
            
            environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
                if let threads: [DiscussionThread] = result.data, owner = self {
                    owner.searchResults = threads
                    owner.environment.router?.showPostsViewController(owner)
                }
            }
        }
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    
    // MARK: - TableView Data and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topicsArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //TODO: this the temp height for each cell, adjust it when final UI is ready.
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionTopicsCell.identifier, forIndexPath: indexPath) as! DiscussionTopicsCell
        
        cell.titleText = self.topicsArray[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        searchResults = nil
        selectedTopic = DiscussionTopicsViewController.getSelectedTopic(indexPath.row, allTopics: self.topics)
        if let topic = selectedTopic, topicID = topic.id {
            environment.router?.showPostsViewController(self)
            
            searchBar.resignFirstResponder()
            self.view.endEditing(true)
        }
    }
    
    
    static func getSelectedTopic(row: Int, allTopics: [Topic]) -> Topic? {
        var i = 0
        for topic in allTopics {
            if let children = topic.children {
                if row == i {
                    return topic
                }
                else if row <= i + children.count {
                    return children[row - i - 1]
                }
                else {
                    i += (children.count + 1)
                }
            }
            else {
                i++
            }
        }
        return nil
    }
}
