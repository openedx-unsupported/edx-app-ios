//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var largeTextStyle : OEXTextStyle {
    let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
    style.color = OEXStyles.sharedStyles().neutralDark()
    return style
}

private var mediaTextStyle : OEXTextStyle {
    let style = OEXMutableTextStyle(font: .ThemeSans, size: 12.0)
    style.color = OEXStyles.sharedStyles().neutralDark()
    return style
}

private var smallTextStyle : OEXTextStyle {
    let style = OEXMutableTextStyle(font: .ThemeSans, size: 10.0)
    style.color = OEXStyles.sharedStyles().neutralDark()
    return style
}

class DiscussionCommentCell: UITableViewCell {
    
    private let bodyTextLabel = UILabel()
    private let authorLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let commentOrFlagIconButton = UIButton.buttonWithType(.System) as! UIButton
    private let commmentCountOrReportIconButton = UIButton.buttonWithType(.System) as! UIButton
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        largeTextStyle.applyToLabel(bodyTextLabel)
        bodyTextLabel.numberOfLines = 3
        contentView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(8)
            make.trailing.equalTo(contentView).offset(-8)
            make.top.equalTo(contentView).offset(5)
        }
        
        smallTextStyle.applyToLabel(authorLabel)
        contentView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bodyTextLabel)
            make.width.equalTo(80)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
        
        smallTextStyle.applyToLabel(dateTimeLabel)
        contentView.addSubview(dateTimeLabel)
        dateTimeLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
            make.width.equalTo(100)
            make.leading.equalTo(authorLabel.snp_trailing).offset(2)
        }

    
        contentView.addSubview(commmentCountOrReportIconButton)
        commmentCountOrReportIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        commmentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-5)
            make.width.equalTo(100)
            make.top.equalTo(bodyTextLabel.snp_bottom)
        }
        
        contentView.addSubview(commentOrFlagIconButton)
        commentOrFlagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        commentOrFlagIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(commmentCountOrReportIconButton.snp_leading)
            make.width.equalTo(14)
            make.top.equalTo(bodyTextLabel.snp_bottom)
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
    private let identifierCommentCell = "CommentCell"
    private let environment: DiscussionCommentsViewControllerEnvironment
    var tableView: UITableView!
    
    init(env: DiscussionCommentsViewControllerEnvironment) {
        self.environment = env
        super.init(nibName: nil, bundle: nil)        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // TOOD: replace with API return or core data query
    var cellValues = [["body": "This is a response. Swine turkey boudin frankfurter. Short loin flank boudin port chop short ribs.", "by": "Student GHJK", "datetime": "2 days ago", "note": "4 comments"],
        ["body": "This is a comment..", "by": "Student EDC", "datetime": "48 minutes ago", "note": "Report"],
        ["body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "datetime": "48 minutes ago", "note": "Report"],
        ["body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "datetime": "48 minutes ago", "note": "Report"],
        ["body": "This is a comment. Andouille kevin pancetta hamburger pig prosciutto ribeye turkey tongue. Pancetta bresaola shank kielbasa andouille jerky short ribs ground round.", "by": "Student EDC", "datetime": "48 minutes ago", "note": "Report"]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = OEXLocalizedString("COMMENTS", nil)
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        if let theTableView = tableView {
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
        if indexPath.row == 0 {
            return 90; // response
        }
        else {
            return 100; // comments
        }
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellValues.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell
        cell.bodyTextLabel.text = cellValues[indexPath.row]["body"]
        cell.authorLabel.text = cellValues[indexPath.row]["by"]
        cell.dateTimeLabel.text = cellValues[indexPath.row]["datetime"]
        cell.commmentCountOrReportIconButton.titleLabel?.font = Icon.fontWithSize(12)
        cell.commmentCountOrReportIconButton.setTitle(cellValues[indexPath.row]["note"], forState: .Normal)
        
        cell.commentOrFlagIconButton.titleLabel?.font = Icon.fontWithSize(12)
        cell.commentOrFlagIconButton.setTitle(indexPath.row == 0 ? Icon.Comment.textRepresentation : Icon.ReportFlag.textRepresentation, forState: .Normal)
        cell.commentOrFlagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
}
