//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

let cellTypeResponse = 1
let cellTypeComment = 2


class DiscussionCommentCell: UITableViewCell {
    
    var bodyTextLabel = UILabel()
    var authorLabel = UILabel()
    var dttmLabel = UILabel()
    var flagIconButton = UIButton()
    var reportButton = UIButton()
    
    var bodyTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    var authordttmTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 12.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bodyTextStyle.applyToLabel(bodyTextLabel)
        bodyTextLabel.numberOfLines = 3
        contentView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(8)
            make.trailing.equalTo(contentView).offset(-8)
            make.top.equalTo(contentView).offset(5)
            make.height.equalTo(70)
            //make.centerY.equalTo(contentView).offset(0)
        }
        
        authordttmTextStyle.applyToLabel(authorLabel)
        contentView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            //make.leading.equalTo(contentView).offset(8)
            // should be the same:
            make.leading.equalTo(bodyTextLabel)
            
            make.width.equalTo(80)
            make.height.equalTo(20)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
        
        authordttmTextStyle.applyToLabel(dttmLabel)
        contentView.addSubview(dttmLabel)
        dttmLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
            make.width.equalTo(100)
            make.height.equalTo(20)
            make.leading.equalTo(authorLabel.snp_trailing).offset(2)
        }

    
        contentView.addSubview(reportButton)
        reportButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        reportButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-5)
            make.width.equalTo(100)
            make.height.equalTo(20)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(6)
        }
        
        contentView.addSubview(flagIconButton)
        flagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        flagIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(reportButton.snp_leading).offset(3)
            make.width.equalTo(10)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
    
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class DiscussionCommentResponseCell: UITableViewCell {
    
    var bodyTextLabel = UILabel()
    var authorLabel = UILabel()
    var dttmLabel = UILabel()
    var bubbleIconButton = UIButton()
    var commentCountButton = UIButton()
    
    var bodyTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    var authordttmTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 12.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bodyTextStyle.applyToLabel(bodyTextLabel)
        bodyTextLabel.numberOfLines = 3
        contentView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(8)
            make.trailing.equalTo(contentView).offset(-8)
            make.top.equalTo(contentView).offset(5)
            make.height.equalTo(60)
            //make.centerY.equalTo(contentView).offset(0)
        }
        
        authordttmTextStyle.applyToLabel(authorLabel)
        contentView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            //make.leading.equalTo(contentView).offset(8)
            // should be the same:
            make.leading.equalTo(bodyTextLabel)
            
            make.width.equalTo(80)
            make.height.equalTo(20)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
        
        authordttmTextStyle.applyToLabel(dttmLabel)
        contentView.addSubview(dttmLabel)
        dttmLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
            make.width.equalTo(100)
            make.height.equalTo(20)
            make.leading.equalTo(authorLabel.snp_trailing).offset(2)
        }
        
        
        contentView.addSubview(commentCountButton)
        commentCountButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        commentCountButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-5)
            make.width.equalTo(120)
            make.height.equalTo(20)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(6)
        }
        
        contentView.addSubview(bubbleIconButton)
        bubbleIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        bubbleIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(commentCountButton.snp_leading).offset(5)
            make.width.equalTo(15)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class DiscussionCommentsViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}


class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let identifierResponseCell = "ResponseCell"
    let identifierCommentCell = "CommentCell"
    var environment: DiscussionCommentsViewControllerEnvironment!    
    var tableView: UITableView!

    // TOOD: replace with API return or core data query
    var cellValues = [  ["type" : cellTypeResponse, "body": "This is a response. Swine turkey boudin frankfurter. Short loin flank boudin port chop short ribs.", "by": "Student GHJK", "dttm": "2 days ago", "note": "4 comments"],
        ["type" : cellTypeComment, "body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "dttm": "48 minutes ago", "note": "Report"],
        ["type" : cellTypeComment, "body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "dttm": "48 minutes ago", "note": "Report"],
        ["type" : cellTypeComment, "body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "dttm": "48 minutes ago", "note": "Report"],
        ["type" : cellTypeComment, "body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "dttm": "48 minutes ago", "note": "Report"]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Comments";
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        self.navigationController!.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController!.navigationBar.barTintColor = OEXStyles.sharedStyles().primaryBaseColor()
        
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        if let theTableView = tableView {
            theTableView.registerClass(DiscussionCommentResponseCell.classForCoder(), forCellReuseIdentifier: identifierResponseCell)
            theTableView.registerClass(DiscussionCommentCell.classForCoder(), forCellReuseIdentifier: identifierCommentCell)
            theTableView.dataSource = self
            theTableView.delegate = self
            view.addSubview(theTableView)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view)
            make.top.equalTo(view).offset(10)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        tableView.reloadData()
        
        
    }
    // MARK - tableview delegate methods
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeResponse {
            return 100;
        }
        else {
            return 110;
        }
    }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellValues.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if cellValues[indexPath.row]["type"] as! Int == cellTypeResponse {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierResponseCell, forIndexPath: indexPath) as! DiscussionCommentResponseCell
            
            cell.bodyTextLabel.text = cellValues[indexPath.row]["body"] as? String
            cell.authorLabel.text = cellValues[indexPath.row]["by"] as? String
            cell.dttmLabel.text = cellValues[indexPath.row]["dttm"] as? String
            cell.bubbleIconButton.titleLabel?.font = Icon.fontWithSize(12)
            cell.bubbleIconButton.setTitle(Icon.Comment.textRepresentation, forState: .Normal)
            cell.bubbleIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
            cell.commentCountButton.setTitle(cellValues[indexPath.row]["note"] as? String, forState: .Normal)
            return cell
        }
        else {
            var cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell
            cell.bodyTextLabel.text = cellValues[indexPath.row]["body"] as? String
            cell.authorLabel.text = cellValues[indexPath.row]["by"] as? String
            cell.dttmLabel.text = cellValues[indexPath.row]["dttm"] as? String
            cell.reportButton.setTitle(cellValues[indexPath.row]["note"] as? String, forState: .Normal)
            cell.flagIconButton.titleLabel?.font = Icon.fontWithSize(12)
            cell.flagIconButton.setTitle(Icon.ReportFlag.textRepresentation, forState: .Normal)
            cell.flagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
}
