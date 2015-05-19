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
    
    init(config: OEXConfig, router: OEXRouter) {
        self.config = config
        self.router = router
    }
}

class DiscussionTopicsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    private let environment: DiscussionTopicsViewControllerEnvironment
    private let course: OEXCourse
    
    private var searchBarContainer: UIView = UIView()
    private var searchBarLabel: UILabel = UILabel()
    
    // TODO: adjust each value once the final UI is out
    let LABEL_SIZE_HEIGHT = 20.0
    let SEARCHBARCONTAINER_SIZE_HEIGHT = 40.0
    let TEXT_MARGIN = 10.0
    
    var searchBarTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 13.0)
        style.color = OEXStyles.sharedStyles().neutralBlack()
        return style
    }
    
    private var tableView: UITableView = UITableView()
    private var selectedIndexPath: NSIndexPath?
    
    var topicsArray : [String] = []
    
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
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        // TODO: "Search all Posts" is just a tempoary string, will be replaced with the right one once the final UI is ready
        searchBarLabel.text = "Search all Posts"
        searchBarTextStyle.applyToLabel(searchBarLabel)
        
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
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.top.equalTo(searchBarContainer.snp_bottom)
            make.bottom.equalTo(self.view)
        }
        
        // Register tableViewCell
        tableView.registerClass(DiscussionTopicsCell.self, forCellReuseIdentifier: DiscussionTopicsCell.identifier)
        
        prepareTableViewData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedIndexPath {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        self.navigationController?.navigationBarHidden = false
    }
    
    // TODO: This is just the temp data. Once the Final UI and API are ready, using OEXLocalizedString function instead
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
        //TODO: this the temp height for each cell, adjust it when final UI is ready.
        return 60.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionTopicsCell.identifier, forIndexPath: indexPath) as! DiscussionTopicsCell
        
        cell.titleLabel.text = self.topicsArray[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        //TODO
    }

}
