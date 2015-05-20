//
//  PostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/19/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

let cellTypeTitleAndBy = 1
let cellTypeTitleOnly = 2

class PostViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MenuOptionsDelegate {
    
    let identifierTitleAndByCell = "TitleAndByCell"
    let identifierTitleOnlyCell = "TitleOnlyCell"
    
    var tableView: UITableView!
    var btnPosts: UIButton!
    var btnActivity: UIButton!
    var viewSeparator: UIView!
    
    var viewOption: UIView!
    var viewControllerOption: MenuOptionsViewController!
    let sortByOptions = [OEXLocalizedString("RECENT_ACTIVITY", nil) as String, OEXLocalizedString("MOST_ACTIVITY", nil) as String, OEXLocalizedString("MOST_VOTES", nil) as String]
    let filteringOptions = [OEXLocalizedString("ALL_POSTS", nil) as String, OEXLocalizedString("UNREAD", nil) as String, OEXLocalizedString("UNANSWERED", nil) as String]
    
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
        self.navigationController!.navigationBar.barTintColor = OEXStyles.sharedStyles().primaryBaseColor()
        
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        
        view.backgroundColor = UIColor.whiteColor()
        
        btnPosts = UIButton.buttonWithType(.System) as? UIButton
        btnPosts.setTitle(OEXLocalizedString("ALL_POSTS", nil), forState: .Normal)
        btnPosts.addTarget(self,
            action: "postsTapped:", forControlEvents: .TouchUpInside)
        view.addSubview(btnPosts)
        
        btnPosts.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view).offset(20)
            make.top.equalTo(view).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(103)
        }
        
        btnActivity = UIButton.buttonWithType(.System) as? UIButton
        btnActivity.setTitle(OEXLocalizedString("RECENT_ACTIVITY", nil), forState: .Normal)
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
            theTableView.registerClass(PostTitleByTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleAndByCell)
            theTableView.registerClass(PostTitleTableViewCell.classForCoder(), forCellReuseIdentifier: identifierTitleOnlyCell)
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
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: viewControllerOption.menuWidth, height: viewControllerOption.menuHeight)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
            }, completion: nil)
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
        viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -101, width: viewControllerOption.menuWidth, height: viewControllerOption.menuHeight)
        self.view.addSubview(viewControllerOption.view)
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: btnTapped.frame.origin.x, y: -1, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
            }, completion: nil)
    }
    
    func optionSelected(selectedRow: Int, sender: AnyObject) {
        if isFilteringOptionsShowing! {
            btnPosts.setTitle(filteringOptions[selectedRow], forState: .Normal)
        }
        else {
            btnActivity.setTitle(sortByOptions[selectedRow], forState: .Normal)
        }
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.frame = CGRect(x: self.viewControllerOption.view.frame.origin.x, y: -101, width: self.viewControllerOption.menuWidth, height: self.viewControllerOption.menuHeight)
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
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleAndByCell, forIndexPath: indexPath) as! PostTitleByTableViewCell
            
            cell.typeImageView.image = UIImage(named:"logo.png")
            cell.titleLabel.text = cellValues[indexPath.row]["title"] as? String
            cell.byImageView.image = UIImage(named:"check.png")
            cell.byLabel.text = cellValues[indexPath.row]["by"] as? String
            cell.countButton.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: .Normal)
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierTitleOnlyCell, forIndexPath: indexPath) as! PostTitleTableViewCell
            cell.typeImageView.image = UIImage(named:"downloading.png")
            cell.titleLabel.text = cellValues[indexPath.row]["title"] as? String
            cell.countButton.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: UIControlState.Normal)
            return cell
        }
    }
}



