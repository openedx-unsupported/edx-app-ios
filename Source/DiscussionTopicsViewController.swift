//
//  DiscussionTopicsViewController.swift
//  edX
/**
Copyright (c) 2015 Qualcomm Education, Inc.
All rights reserved.


Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

* Neither the name of Qualcomm Education, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

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

    private var environment: DiscussionTopicsViewControllerEnvironment
    private var course: OEXCourse
    
    private var searchBarContainer: UIView = UIView()
    private var searchBarLabel: UILabel = UILabel()
    
    var searchBarTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 13.0)
        style.color = OEXStyles.sharedStyles()?.neutralBlack()
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
        
        self.view.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        self.view.addSubview(tableView)
        
        // TODO: Temp font and color
        searchBarLabel.text = "Search all Posts"
        searchBarTextStyle.applyToLabel(searchBarLabel)
        
        searchBarContainer.addSubview(searchBarLabel)
        searchBarContainer.backgroundColor = UIColor.clearColor()
        
        self.view.addSubview(searchBarContainer)
        
        searchBarContainer.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.height.equalTo(40)
        }
        searchBarLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.searchBarContainer).offset(40)
            make.right.equalTo(self.searchBarContainer).offset(-10)
            make.centerY.equalTo(self.searchBarContainer)
            make.height.equalTo(20)
        }
        
        tableView.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
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
