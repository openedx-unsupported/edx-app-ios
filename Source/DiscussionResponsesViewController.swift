//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public enum DiscussionItem {
    case Post(DiscussionPostItem)
    case Response(DiscussionResponseItem)
    
    var threadID : String {
        switch self {
            case let .Post(item): return item.threadID
            case let .Response(item): return item.threadID
        }
    }
    
    var responseID : String? {
        switch self {
            case let .Post(item): return nil
            case let .Response(item): return item.responseID
        }
    }
    
    var title: String? {
        switch self {
            case let .Post(item): return item.title
            case let .Response(item): return nil
        }
    }
    
    var body: String {
        switch self {
        case let .Post(item): return item.body
        case let .Response(item): return item.body
        }
    }
    
    var createdAt: NSDate {
        switch self {
        case let .Post(item): return item.createdAt
        case let .Response(item): return item.createdAt
        }
    }
    
    var author: String {
        switch self {
        case let .Post(item): return item.author
        case let .Response(item): return item.author
        }
    }
    
    var isResponse : Bool {
        return self.responseID != nil
    }
}

public struct DiscussionResponseItem {
    let body: String
    let author: String
    let createdAt: NSDate
    var voteCount: Int
    let responseID: String
    let threadID: String
    let flagged: Bool
    var voted: Bool
    let children: [DiscussionComment]
}

private let GeneralPadding: CGFloat = 8.0

private var cellButtonStyle = OEXTextStyle().withSize(.Base).withColor(OEXStyles.sharedStyles().primaryBaseColor())
private var responseCountStyle : OEXTextStyle {
    return OEXTextStyle().withSize(.Small).withColor(OEXStyles.sharedStyles().primaryBaseColor())
}

class DiscussionCellButton: UIButton {
    var row: Int?
}

class DiscussionPostCell: UITableViewCell {
    static let identifier = "DiscussionPostCell"

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var bodyTextLabel: UILabel!
    @IBOutlet private var visibilityLabel: UILabel!
    @IBOutlet private var authorLabel: UILabel!
    @IBOutlet private var responseCountLabel:UILabel!
    @IBOutlet private var voteButton: DiscussionCellButton!
    @IBOutlet private var followButton: DiscussionCellButton!
    @IBOutlet private var reportButton: DiscussionCellButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for (button, icon, text) in [
            (voteButton, Icon.UpVote, "2 Votes"), // TODO: put in real data
            (followButton, Icon.FollowStar, OEXLocalizedString("DISCUSSION_FOLLOW", nil)),
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))
            ]
        {
            let buttonText = NSAttributedString.joinInNaturalLayout(
                before: icon.attributedTextWithStyle(cellButtonStyle),
                after: cellButtonStyle.attributedStringWithText(text))
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var bodyTextLabel: UILabel!
    @IBOutlet private var authorLabel: UILabel!
    @IBOutlet private var voteButton: DiscussionCellButton!
    @IBOutlet private var reportButton: DiscussionCellButton!
    @IBOutlet private var bubbleIconButton: DiscussionCellButton!
    @IBOutlet private var commentButton: DiscussionCellButton!
    @IBOutlet private var commentBox: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        for (button, icon, text) in [
            (bubbleIconButton, Icon.Comment, nil as String?),
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))]
        {
            let iconString = icon.attributedTextWithStyle(cellButtonStyle)
            let buttonText : NSAttributedString
            if let text = text {
                buttonText = NSAttributedString.joinInNaturalLayout(
                before: iconString,
                after: cellButtonStyle.attributedStringWithText(text))
            }
            else {
                buttonText = iconString
            }
            button.setAttributedTitle(buttonText, forState:.Normal)
        }

        containerView.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        containerView.layer.masksToBounds = true;
        commentBox.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
    }
}

class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    class Environment {
        weak var router: OEXRouter?
        let networkManager : NetworkManager?
        
        init(networkManager : NetworkManager?, router: OEXRouter?) {
            self.networkManager = networkManager
            self.router = router
        }
    }

    
    var environment: Environment!
    var courseID : String!
    
    @IBOutlet var tableView: UITableView!
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    private var responses : [DiscussionResponseItem]  = []
    var postItem: DiscussionPostItem?
    var postFollowing = false
    
    
    override func viewDidLoad() {
        assert(environment != nil)
        assert(courseID != nil)
        
        super.viewDidLoad()
        
        self.navigationItem.title = OEXLocalizedString("DISCUSSION_POST", nil)
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        addResponseButton.backgroundColor = OEXStyles.sharedStyles().primaryXDarkColor()

        let style = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(style.withSize(.XSmall)),
            after: style.attributedStringWithText(OEXLocalizedString("ADD_A_RESPONSE", nil)))
        addResponseButton.setAttributedTitle(buttonTitle, forState: .Normal)
                
        addResponseButton.contentVerticalAlignment = .Center
        
        addResponseButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            if let owner = self, item = owner.postItem {
                owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, item: DiscussionItem.Post(item))
            }
        }, forEvents: UIControlEvents.TouchUpInside)
        
        view.addSubview(addResponseButton)
        addResponseButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(DiscussionStyleConstants.standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
        }

        markPostAsRead()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let item = postItem {
            let apiRequest = DiscussionAPI.getResponses(item.threadID)
            postFollowing = item.following
            
            environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
                
                if let allResponses : [DiscussionComment] = result.data {
                    self?.responses.removeAll(keepCapacity: true)
                    
                    for response in allResponses {
                        if  let body = response.rawBody,
                            author = response.author,
                            createdAt = response.createdAt,
                            threadID = response.threadId,
                            children = response.children {
                                
                                let voteCount = response.voteCount
                                let item = DiscussionResponseItem(
                                    body: body,
                                    author: author,
                                    createdAt: createdAt,
                                    voteCount: voteCount,
                                    responseID: response.commentID,
                                    threadID: threadID,
                                    flagged: response.flagged,
                                    voted: response.voted,
                                    children: children)
                                
                                self?.responses.append(item)
                        }
                    }
                    
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, row = button.row {
            environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, item: responses[row])
        }
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return responses.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
            if let item = postItem {
                cell.titleLabel.text = item.title
                cell.bodyTextLabel.text = item.body
                cell.visibilityLabel.text = "" // This post is visible to cohort test" // TODO: figure this out
                cell.authorLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            }
            
            let icon = Icon.Comment.attributedTextWithStyle(responseCountStyle)
            let countLabelText = NSAttributedString(string: NSString.oex_stringWithFormat(OEXLocalizedStringPlural("RESPONSE", Float(responses.count), nil), parameters: ["count": Float(responses.count)]))
            let labelText = NSAttributedString.joinInNaturalLayout(before: icon, after: countLabelText)
            
            cell.responseCountLabel.attributedText = labelText
            
            // vote a post (thread) - User can only vote on post and response not on comment.
            cell.voteButton.oex_removeAllActions()
            cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                if let owner = self, button = action as? DiscussionCellButton, item = owner.postItem {
                    let apiRequest = DiscussionAPI.voteThread(item.voted, threadID: item.threadID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        if let thread: DiscussionThread = result.data {
                            let voteCount = item.voted ? item.voteCount - 1 : item.voteCount + 1
                            owner.updateVoteText(cell.voteButton, voteCount: voteCount, voted: thread.voted)
                            owner.postItem?.voteCount = voteCount
                            owner.postItem?.voted = thread.voted
                        }
                    }
                }
            }, forEvents: UIControlEvents.TouchUpInside)
            
            // follow a post (thread) - User can only follow original post, not response or comment.
            cell.followButton.oex_removeAllActions()
            cell.followButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                if let owner = self, button = action as? DiscussionCellButton, item = owner.postItem {
                    let apiRequest = DiscussionAPI.followThread(owner.postFollowing, threadID: item.threadID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        if let thread: DiscussionThread = result.data {
                            owner.updateFollowText(cell.followButton, following: thread.following)
                            owner.postFollowing = thread.following
                        }
                    }
                }
            }, forEvents: UIControlEvents.TouchUpInside)
            
            if let item = postItem {
                updateVoteText(cell.voteButton, voteCount: item.voteCount, voted: item.voted)
                updateFollowText(cell.followButton, following: item.following)
            }
            
            // report (flag) a post (thread) - User can report on post, response, or comment.
            cell.reportButton.oex_removeAllActions()
            cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                if let owner = self, button = action as? DiscussionCellButton, item = owner.postItem {
                    let apiRequest = DiscussionAPI.flagThread(item.flagged, threadID: item.threadID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        if let thread: DiscussionThread = result.data {
                            // TODO: update UI after API is done
                        }
                    }
                }
            }, forEvents: UIControlEvents.TouchUpInside)
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
            cell.bodyTextLabel.text = responses[indexPath.row].body
            cell.authorLabel.text = DateHelper.socialFormatFromDate(responses[indexPath.row].createdAt) +  " " + responses[indexPath.row].author
            let commentCount = responses[indexPath.row].children.count
            if commentCount == 0 {
                cell.commentButton.setTitle(OEXLocalizedString("ADD_A_COMMENT", nil), forState: .Normal)
            }
            else {
                cell.commentButton.setTitle(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("COMMENTS_TO_RESPONSE", Float(commentCount), nil), parameters: ["count": Float(commentCount)]), forState: .Normal)
            }
            let voteCount = responses[indexPath.row].voteCount
            let voted = responses[indexPath.row].voted
            cell.commentButton.row = indexPath.row
            cell.bubbleIconButton.row = indexPath.row

            
            //cell.voteButton.setTitle(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("VOTE", Float(voteCount), nil), parameters: ["count": Float(voteCount)]), forState: .Normal)
            updateVoteText(cell.voteButton, voteCount: voteCount, voted: voted)
            
            cell.voteButton.row = indexPath.row
            // vote/unvote a response - User can vote on post and response not on comment.
            cell.voteButton.oex_removeAllActions()
            cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                if let owner = self, button = action as? DiscussionCellButton, row = button.row {
                    let voted = owner.responses[row].voted
                    let apiRequest = DiscussionAPI.voteResponse(voted, responseID: owner.responses[row].responseID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        if let response: DiscussionComment = result.data {
                            owner.responses[row].voted = response.voted
                            let voteCount = voted ? owner.responses[row].voteCount - 1 : owner.responses[row].voteCount + 1
                            owner.responses[row].voteCount = voteCount
                            owner.updateVoteText(cell.voteButton, voteCount: voteCount, voted: response.voted)
                        }
                    }
                }
            }, forEvents: UIControlEvents.TouchUpInside)
            
            
            cell.reportButton.row = indexPath.row
            // report (flag)/unflag a response - User can report on post, response, or comment.
            cell.reportButton.oex_removeAllActions()
            cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                if let owner = self, button = action as? DiscussionCellButton, row = button.row {
                    let apiRequest = DiscussionAPI.flagComment(owner.responses[row].flagged, commentID: owner.responses[row].responseID)
                    
                    owner.environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                        // result.error: Optional(Error Domain=org.edx.error Code=-100 "Unable to load course content.
                        if let response: DiscussionComment = result.data {
                            // TODO: update UI after API is done
                        }
                    }
                }
            }, forEvents: UIControlEvents.TouchUpInside)
            
            return cell
        }
    }

    private func updateVoteText(button: DiscussionCellButton, voteCount: Int, voted: Bool) {
        // TODO: show upvote and downvote depending on voted?
        let buttonText = NSAttributedString.joinInNaturalLayout(
            before: Icon.UpVote.attributedTextWithStyle(cellButtonStyle),
            after: cellButtonStyle.attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("VOTE", Float(voteCount), nil), parameters: ["count": Float(voteCount)])))
        
        button.setAttributedTitle(buttonText, forState:.Normal)
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let buttonText = NSAttributedString.joinInNaturalLayout(
            before: Icon.FollowStar.attributedTextWithStyle(cellButtonStyle),
            after: cellButtonStyle.attributedStringWithText(OEXLocalizedString(following ? "DISCUSSION_UNFOLLOW" : "DISCUSSION_FOLLOW", nil)))
        button.setAttributedTitle(buttonText, forState:.Normal)
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 0 {
            cell.backgroundColor = UIColor.clearColor()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 200.0
        } else {
            return 210.0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO
    }
    
    //MARK: Helper Methods
    func markPostAsRead() {
// TODO: Complete the implementation when "read" is writeable
        
//        if let item = postItem {
//           let apiRequest = DiscussionAPI.markThreadAsRead(true, threadID: item.threadID)
//            self.environment.networkManager?.taskForRequest(apiRequest) { [weak self] result in
//                if let discussionThread = result.data {
//                    //TODO: Send notification to the previous screen to update the data OR reload it (notification would be better)
//                }
//                
//            }
//        }
        
    }
    
}