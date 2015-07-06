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
    let networkManager : NetworkManager?
    weak var router: OEXRouter?
    
    init(config: OEXConfig, networkManager : NetworkManager, router: OEXRouter) {
        self.config = config
        self.networkManager = networkManager
        self.router = router
    }
}

class DiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    private let environment: DiscussionTopicsViewControllerEnvironment
    let course: OEXCourse
    
    private var searchBarContainer: UIView = UIView()
    private var searchBarLabel: UILabel = UILabel()
    
    // TODO: adjust each value once the final UI is out
    let LABEL_SIZE_HEIGHT = 20.0
    let SEARCHBARCONTAINER_SIZE_HEIGHT = 40.0
    let TEXT_MARGIN = 10.0
    let TABLEVIEW_LEADING_MARGIN = 30.0
    
    var searchBarTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBlack())
    }
    
    private var tableView: UITableView = UITableView()
    private var selectedIndexPath: NSIndexPath?
    
    var topicsArray: [String] = []
    var topics: [DiscussionTopic]?
    var selectedTopic: String?
    
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
        
        // TODO: "Search all Posts" is just a tempoary string, will be replaced with the right one once the final UI is ready
        searchBarLabel.attributedText = searchBarTextStyle.attributedStringWithText("Search all Posts")
        
        searchBarContainer.addSubview(searchBarLabel)
        searchBarContainer.backgroundColor = UIColor.clearColor()
        
        self.view.addSubview(searchBarContainer)
        
        searchBarContainer.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(self.view)
            make.height.equalTo(SEARCHBARCONTAINER_SIZE_HEIGHT)
        }
        searchBarLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.searchBarContainer).offset(TEXT_MARGIN)
            make.trailing.equalTo(self.searchBarContainer).offset(-TEXT_MARGIN)
            make.centerY.equalTo(self.searchBarContainer)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.view).offset(-TABLEVIEW_LEADING_MARGIN)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBarContainer.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicsCell.self, forCellReuseIdentifier: DiscussionTopicsCell.identifier)
        
        let apiRequest = DiscussionAPI.getCourseTopics(self.course.course_id!)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            self?.topics = result.data!
            
            // TODO: Use OEXLocalizedString?
            if let topics = self?.topics {
                for topic in topics {
                    if let name = topic.name {
                        self?.topicsArray.append(name)
                        if topic.children != nil {
                            for child in topic.children! {
                                if let childName = child.name {
                                    self?.topicsArray.append("     \(childName)")
                                }
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
        selectedTopic = topicsArray[indexPath.row].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())      
        environment.router?.showPostsViewController(self)
    }
    

}
