//
//  PostViewControllerUsingStoryboard.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

let cellTypeTitleAndBy = 1
let cellTypeTitleOnly = 2

class PostViewControllerUsingStoryboard: UIViewController, UITableViewDataSource, UITableViewDelegate, MenuOptionsDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnPosts: UIButton!
    @IBOutlet weak var btnActivity: UIButton!
    
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

        // Do any additional setup after loading the view.
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
            
            cell.lblBy.text = cellValues[indexPath.row]["by"] as? String
            cell.lblTitle!.text = cellValues[indexPath.row]["title"] as? String
            cell.btnCount.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: .Normal)
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier("TitleOnlyCell", forIndexPath: indexPath) as! PostTitleTableViewCell
            cell.lblTitle!.text = cellValues[indexPath.row]["title"] as? String
            cell.btnCount.setTitle(String(cellValues[indexPath.row]["count"] as! Int), forState: UIControlState.Normal)
            return cell
        }
    }
}



