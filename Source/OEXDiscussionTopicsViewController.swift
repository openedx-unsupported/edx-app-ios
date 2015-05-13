//
//  OEXDiscussionTopicsViewController.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/7/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class OEXDiscussionTopicsViewControllerEnvironment : NSObject {
    weak var config: OEXConfig?
    weak var router: OEXRouter?
    
    init(config: OEXConfig, router: OEXRouter) {
        self.config = config
        self.router = router
    }
}

class OEXDiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var environment: OEXDiscussionTopicsViewControllerEnvironment
    private var course: OEXCourse
    
    var searchBarContainer: UIView = UIView()
    var searchBarLabel: UILabel = UILabel()
    
    var tableView: UITableView = UITableView()
    
    
    var topicsArray = NSArray()
    
    init(environment: OEXDiscussionTopicsViewControllerEnvironment, course: OEXCourse) {
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
        
        self.view.backgroundColor = UIColor(red: 227.0/255.0, green: 227.0/255.0, blue: 227.0/255.0, alpha: 1.0)
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        // TODO: Temp font and color
        searchBarLabel.text = "Search all Posts"
        searchBarLabel.textColor = UIColor.blackColor()
        searchBarLabel.font = UIFont(name: "HelveticaNeue", size: CGFloat(13))
        
        searchBarContainer.addSubview(searchBarLabel)
        searchBarContainer.backgroundColor = UIColor.clearColor()
        
        self.view.addSubview(searchBarContainer)
        
        searchBarContainer.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.view).offset(0)
            make.right.equalTo(self.view).offset(0)
            make.top.equalTo(self.view).offset(0)
            make.height.equalTo(40)
        }
        searchBarLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.searchBarContainer).offset(40)
            make.right.equalTo(self.searchBarContainer).offset(-10)
            make.centerY.equalTo(self.searchBarContainer).offset(0)
            make.height.equalTo(20)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.view).offset(0)
            make.right.equalTo(self.view).offset(0)
            make.top.equalTo(searchBarContainer.snp_bottom).offset(0)
            make.bottom.equalTo(self.view).offset(0)
        }
        
        
        // Register tableViewCell
        tableView.registerClass(OEXDiscussionTopicsCell.self, forCellReuseIdentifier: OEXDiscussionTopicsCell.identifier)
        
        prepareTableViewData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // TODO: this is the temp data
    func prepareTableViewData() {
        
        self.topicsArray = ["All Posts", "Posts I'm Following", "General", "Feedback",
            "Troubleshooting", "SignalsGroup", "Overview", "Using the tools", "Week 1", "Week 2"]
        
    }
    
    // MARK: - TableView Data and Delegate
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topicsArray.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(OEXDiscussionTopicsCell.identifier, forIndexPath: indexPath) as! OEXDiscussionTopicsCell
        
        cell.titleLabel.text = self.topicsArray.objectAtIndex(indexPath.row) as? String
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }
    
}
