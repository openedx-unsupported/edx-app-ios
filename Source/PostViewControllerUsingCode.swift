//
//  PostViewControllerUsingCode.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class PostViewControllerUsingCode: UIViewController, UITableViewDataSource, UITableViewDelegate, MenuOptionsDelegate {
    
    var tableView: UITableView!
    var btnPosts: UIButton!
    var btnActivity: UIButton!
    var viewSeparator: UIView!
    
    var viewOption: UIView!
    var viewControllerOption: MenuOptionsViewController!
    let sortByOptions = ["Recent Activity", "Most Activity", "Most Votes"]
    let filteringOptions = ["All Posts", "Unread", "Unanswered"]
    var isFilteringOptionsShowing: Bool?
    
    
    // TOOD: replace with API return
    var cellValues = [  ["type" : cellTypeTitleAndBy, "title": "Unread post title", "by": "STAFF", "count": 6],
        ["type" : cellTypeTitleAndBy, "title": "Read post with new comments", "by": "STAFF", "count": 5],
        ["type" : cellTypeTitleAndBy, "title": "Read post with read comments", "by": "COMMUNITY TA", "count": 9],
        ["type" : cellTypeTitleOnly, "title": "Unanswered question", "count": 12],
        ["type" : cellTypeTitleOnly, "title": "Answered question", "count": 16],
        ["type" : cellTypeTitleOnly, "title": "Unread post title that is really really very super long", "count": 96],
        ["type" : cellTypeTitleOnly, "title": "Unanswered question", "count": 36],
        ["type" : cellTypeTitleOnly, "title": "Answered question", "count": 66]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Posts I'm Following";
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.navigationController!.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController!.navigationBar.barTintColor = UIColor(red: 17 / 255, green: 137 / 255, blue: 227 / 255, alpha: 1.0)
        
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        
        view.backgroundColor = UIColor.whiteColor()
        
        btnPosts = UIButton.buttonWithType(.System) as? UIButton
        btnPosts.setTitle("All Posts", forState: .Normal)
        btnPosts.addTarget(self,
            action: "postsTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(btnPosts)
        
        btnPosts.snp_makeConstraints{ (make) -> Void in
            make.left.equalTo(view).offset(20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(103)
        }
        
        btnActivity = UIButton.buttonWithType(.System) as? UIButton
        btnActivity.setTitle("Recent Activity", forState: .Normal)
        btnActivity.addTarget(self,
            action: "activityTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(btnActivity)
        
        btnActivity.snp_makeConstraints{ (make) -> Void in
            make.right.equalTo(view).offset(-20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(103)
        }
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        if let theTableView = tableView {
            theTableView.registerClass(PostTitleByTableViewCell.classForCoder(), forCellReuseIdentifier: "TitleAndByCell")
            theTableView.registerClass(PostTitleTableViewCell.classForCoder(), forCellReuseIdentifier: "TitleOnlyCell")
            theTableView.dataSource = self
            theTableView.delegate = self
            view.addSubview(theTableView)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
                make.left.equalTo(view).offset(0)
                make.top.equalTo(btnPosts).offset(30)
                make.right.equalTo(view).offset(0)
                make.bottom.equalTo(view).offset(0)
        }
        
        
        viewSeparator = UIView()
        viewSeparator.backgroundColor = UIColor(red: 236 / 255, green: 236 / 255, blue: 241 / 255, alpha: 1.0)
        view.addSubview(viewSeparator)
        viewSeparator.snp_makeConstraints{ (make) -> Void in
            make.left.equalTo(view).offset(0)
            make.right.equalTo(view).offset(0)
            make.height.equalTo(1)
            make.top.equalTo(btnPosts.snp_bottom).offset(10)
        }
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backTapped(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func postsTapped(sender: AnyObject) {
        if isFilteringOptionsShowing != nil {
            return;
        }
        
        let btnTapped = sender as! UIButton
        isFilteringOptionsShowing = true
        
        viewControllerOption = MenuOptionsViewController()
        viewControllerOption.delegate​ = self
        viewControllerOption.options = filteringOptions
        viewControllerOption.selectedOptionIndex = find(filteringOptions, btnTapped.titleLabel!.text!)
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: MENU_WIDTH, height: MENU_HEIGHT)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: MENU_WIDTH, height: MENU_HEIGHT)
            }, completion: {[weak self] (finished: Bool) in
            })
    }
    
    @IBAction func activityTapped(sender: AnyObject) {
        if isFilteringOptionsShowing != nil {
            return;
        }
        
        let btnTapped = sender as! UIButton
        isFilteringOptionsShowing = false
        
        viewControllerOption = MenuOptionsViewController()
        viewControllerOption.delegate​ = self
        viewControllerOption.options = sortByOptions
        viewControllerOption.selectedOptionIndex = find(sortByOptions, btnTapped.titleLabel!.text!)
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: MENU_WIDTH, height: MENU_HEIGHT)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: MENU_WIDTH, height: MENU_HEIGHT)
            }, completion: {[weak self] (finished: Bool) in
            })
    }
    
    func optionSelected(selectedRow: Int) {
        if isFilteringOptionsShowing! {
            btnPosts.setTitle(filteringOptions[selectedRow], forState: .Normal)
        }
        else {
            btnActivity.setTitle(sortByOptions[selectedRow], forState: .Normal)
        }
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: self.viewControllerOption.view.frame.origin.x, y: -101, width: MENU_WIDTH, height: MENU_HEIGHT)
            }, completion: {[weak self] (finished: Bool) in
                self!.viewControllerOption.view.removeFromSuperview()
                self!.isFilteringOptionsShowing = nil
            })
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeTitleAndBy {
            return 70;
        }
        else {
            return 50;
        }
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellValues.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeTitleAndBy {
            var cell = tableView.dequeueReusableCellWithIdentifier("TitleAndByCell", forIndexPath: indexPath) as! PostTitleByTableViewCell
            
            println(">>>\(cellValues[indexPath.row])")
                
            cell.ivType.image = UIImage(named:"logo.png")
            cell.lblTitle!.text = cellValues[indexPath.row]["title"] as? String
            cell.ivBy.image = UIImage(named:"check.png")
            cell.lblBy.text = cellValues[indexPath.row]["by"] as? String        
            cell.btnCount.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: .Normal)
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier("TitleOnlyCell", forIndexPath: indexPath) as! PostTitleTableViewCell
            cell.ivType.image = UIImage(named:"downloading.png")        
            cell.lblTitle!.text = cellValues[indexPath.row]["title"] as? String
            cell.btnCount.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: UIControlState.Normal)
            return cell
        }
    }
}



