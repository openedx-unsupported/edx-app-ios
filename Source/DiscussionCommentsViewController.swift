//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var largeTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: 14.0, color : OEXStyles.sharedStyles().neutralDark())
}

private var mediaTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: 12, color : OEXStyles.sharedStyles().neutralDark())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: 10, color : OEXStyles.sharedStyles().neutralDark())
}

class DiscussionCommentCell: UITableViewCell {
    
    private let bodyTextLabel = UILabel()
    private let authorLabel = UILabel()
    private let dateTimeLabel = UILabel()
    private let commentOrFlagIconButton = UIButton.buttonWithType(.System) as! UIButton
    private let commmentCountOrReportIconButton = UIButton.buttonWithType(.System) as! UIButton
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        bodyTextLabel.numberOfLines = 3
        contentView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(8)
            make.trailing.equalTo(contentView).offset(-8)
            make.top.equalTo(contentView).offset(5)
        }
        
        contentView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bodyTextLabel)
            make.width.equalTo(80)
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
        }
        
        contentView.addSubview(dateTimeLabel)
        dateTimeLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom).offset(5)
            make.width.equalTo(100)
            make.leading.equalTo(authorLabel.snp_trailing).offset(2)
        }

    
        contentView.addSubview(commmentCountOrReportIconButton)
        commmentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-5)
            make.width.equalTo(100)
            make.top.equalTo(bodyTextLabel.snp_bottom)
        }
        
        contentView.addSubview(commentOrFlagIconButton)
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
    private let addCommentButton = UIButton.buttonWithType(.System) as! UIButton
    private var tableView: UITableView!
    
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
        
        addCommentButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()
        
        let style = OEXTextStyle(weight : .Normal, size: 16, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(12)),
            after: style.attributedStringWithText(OEXLocalizedString("ADD_A_COMMENT", nil)))
        addCommentButton.setAttributedTitle(buttonTitle, forState: .Normal)
        addCommentButton.contentVerticalAlignment = .Center
        
        weak var weakSelf = self
        addCommentButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentFromController(weakSelf, isResponse: false)
            }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(addCommentButton)
        addCommentButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(60)
            make.bottom.equalTo(view.snp_bottom)
        }
        
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
            make.bottom.equalTo(addCommentButton.snp_top)
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
    
    var commentInfoStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : 12, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell
        cell.bodyTextLabel.attributedText = largeTextStyle.attributedStringWithText(cellValues[indexPath.row]["body"])
        cell.authorLabel.attributedText = smallTextStyle.attributedStringWithText(cellValues[indexPath.row]["by"])
        cell.dateTimeLabel.attributedText = smallTextStyle.attributedStringWithText(cellValues[indexPath.row]["datetime"])
        
        let noteText = cellValues[indexPath.row]["note"]
        cell.commmentCountOrReportIconButton.setAttributedTitle(commentInfoStyle.attributedStringWithText(noteText), forState: .Normal)
        
        let icon = indexPath.row == 0 ? Icon.Comment : Icon.ReportFlag
        cell.commentOrFlagIconButton.setAttributedTitle(icon.attributedTextWithStyle(commentInfoStyle), forState: .Normal)
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
}
