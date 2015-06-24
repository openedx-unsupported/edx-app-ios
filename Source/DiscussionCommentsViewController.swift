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
    let responseItem: DiscussionResponseItem
   
    init(router: OEXRouter?, responseItem: DiscussionResponseItem) {
        self.router = router
        self.responseItem = responseItem
    }
}


 class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NewCommentDelegate {
    private let identifierCommentCell = "CommentCell"
    private let environment: DiscussionCommentsViewControllerEnvironment
    private let addCommentButton = UIButton.buttonWithType(.System) as! UIButton
    private var tableView: UITableView!
    private var comments : [DiscussionResponseItem]  = []
    
    init(env: DiscussionCommentsViewControllerEnvironment) {
        self.environment = env
        super.init(nibName: nil, bundle: nil)        
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = OEXLocalizedString("COMMENTS", nil)
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        addCommentButton.backgroundColor = OEXStyles.sharedStyles().neutralDark()
        
        let createAPostString = OEXLocalizedString("ADD_A_COMMENT", nil)
        let plainText = createAPostString.textWithIconFont(Icon.Create.textRepresentation)
        let styledText = NSMutableAttributedString(string: plainText)
        styledText.setSizeForText(plainText, textSizes: [createAPostString: 16, Icon.Create.textRepresentation: 12])
        styledText.addAttribute(NSForegroundColorAttributeName, value: OEXStyles.sharedStyles().neutralWhite(), range: NSMakeRange(0, count(plainText)))
        
        addCommentButton.setAttributedTitle(styledText, forState: .Normal)
        addCommentButton.contentVerticalAlignment = .Center
        
        weak var weakSelf = self
        addCommentButton.oex_addAction({ (action : AnyObject!) -> Void in
            environment.router?.showDiscussionNewCommentFromController(weakSelf!, isResponse: false, item: weakSelf!.environment.responseItem)
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
        
        
        self.comments.removeAll(keepCapacity: true)
        for result in environment.responseItem.children {
            let item = DiscussionResponseItem(
                body: result["raw_body"].string!,
                author: result["author"].string!,
                createdAt: OEXDateFormatting.dateWithServerString(result["created_at"].string!),
                voteCount: result["vote_count"].int!,
                responseID: result["id"].string!,
                threadID: result["thread_id"].string!,
                children: [])
            
            self.comments.append(item)
        }
        
        tableView.reloadData()
    }
    
    func updateComments(item: DiscussionResponseItem) {
        self.comments.append(item)
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
        return comments.count + 1 // first row for response
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell

        cell.commmentCountOrReportIconButton.titleLabel?.font = Icon.fontWithSize(12)
        
        if indexPath.row == 0 {
            cell.bodyTextLabel.text = environment.responseItem.body
            cell.authorLabel.text = environment.responseItem.author
            cell.dateTimeLabel.text = DateHelper.socialFormatFromDate(environment.responseItem.createdAt)
            cell.commmentCountOrReportIconButton.setTitle("\(comments.count) comments", forState: .Normal)
        }
        else {
            cell.bodyTextLabel.text = comments[indexPath.row - 1].body
            cell.authorLabel.text = comments[indexPath.row - 1].author
            cell.dateTimeLabel.text = DateHelper.socialFormatFromDate(comments[indexPath.row - 1].createdAt)
            cell.commmentCountOrReportIconButton.setTitle("\(comments.count) comments", forState: .Normal)
            cell.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        }
        cell.commentOrFlagIconButton.titleLabel?.font = Icon.fontWithSize(12)
        cell.commentOrFlagIconButton.setTitle(indexPath.row == 0 ? Icon.Comment.textRepresentation : Icon.ReportFlag.textRepresentation, forState: .Normal)
        cell.commentOrFlagIconButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
}
