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

private let cellButtonStyle = OEXTextStyle(weight:.Normal, size:.Base, color: OEXStyles.sharedStyles().primaryBaseColor())
private let responseCountStyle = OEXTextStyle(weight:.Normal, size:.Small, color:OEXStyles.sharedStyles().primaryBaseColor())
private let responseMessageStyle = OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralBase())

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
        self.selectionStyle = .None
        
        for (button, icon, text) in [
            (voteButton, Icon.UpVote, nil as String?),
            (followButton, Icon.FollowStar, OEXLocalizedString("DISCUSSION_FOLLOW", nil)),
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))
            ]
        {
            let buttonText = NSAttributedString.joinInNaturalLayout(
                before: icon.attributedTextWithStyle(cellButtonStyle),
                after: cellButtonStyle.attributedStringWithText(text ?? ""))
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
    @IBOutlet private var commentButton: DiscussionCellButton!
    @IBOutlet private var commentBox: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .None
        
        for (button, icon, text) in [
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))]
        {
            let iconString = icon.attributedTextWithStyle(cellButtonStyle)
            let buttonText = NSAttributedString.joinInNaturalLayout(
                before: iconString,
                after: cellButtonStyle.attributedStringWithText(text))
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
        let styles : OEXStyles
        
        init(networkManager : NetworkManager?, router: OEXRouter?, styles : OEXStyles) {
            self.networkManager = networkManager
            self.router = router
            self.styles = styles
        }
    }

    enum TableSection : Int {
        case Post = 0
        case Responses = 1
    }
    
    var environment: Environment!
    var courseID : String!
    
    @IBOutlet var tableView: UITableView!
    private let addResponseButton = UIButton.buttonWithType(.System) as! UIButton
    private var responses : [DiscussionResponseItem]  = []
    var postItem: DiscussionPostItem?
    var postFollowing = false
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: self.environment.styles.neutralXDark())
    }
    
    var bodyTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: self.environment.styles.neutralDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXXSmall, color: self.environment.styles.neutralBase())

    }
    
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

        let footerStyle = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite())
        let buttonTitle = NSAttributedString.joinInNaturalLayout(
            before: Icon.Create.attributedTextWithStyle(footerStyle.withSize(.XSmall)),
            after: footerStyle.attributedStringWithText(OEXLocalizedString("ADD_A_RESPONSE", nil)))
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
            make.height.equalTo(OEXStyles.sharedStyles().standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
            make.top.equalTo(tableView.snp_bottom)
        }

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let item = postItem {
            let apiRequest = DiscussionAPI.getResponses(item.threadID, markAsRead : true)
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
            let response = responses[row]
            if response.children.count == 0 {
                environment.router?.showDiscussionNewCommentFromController(self, courseID: courseID, item: DiscussionItem.Response(response))
            } else {
                environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, item: response)
            }
        }
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section) {
        case .Some(.Post): return 1
        case .Some(.Responses): return responses.count
        case .None:
            assert(false, "Unknown table section")
            return 0
        }
    }
    
    func cellForPostAtIndexPath(indexPath : NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
        if let item = postItem {
            cell.titleLabel.text = item.title
            cell.bodyTextLabel.text = item.body
            cell.visibilityLabel.text = "" // This post is visible to cohort test" // TODO: figure this out
            cell.authorLabel.text = item.createdAt.timeAgoSinceNow() +  " " + item.author
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

    }
    
    func cellForResponseAtIndexPath(indexPath : NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
        cell.bodyTextLabel.text = responses[indexPath.row].body
        cell.authorLabel.text = responses[indexPath.row].createdAt.timeAgoSinceNow() +  " " + responses[indexPath.row].author
        let commentCount = responses[indexPath.row].children.count
        let prompt : String
        if commentCount == 0 {
            prompt = OEXLocalizedString("ADD_A_COMMENT", nil)
        }
        else {
            prompt = NSString.oex_stringWithFormat(OEXLocalizedStringPlural("COMMENTS_TO_RESPONSE", Float(commentCount), nil), parameters: ["count": commentCount])
        }
        let iconText = Icon.Comment.attributedTextWithStyle(responseMessageStyle)
        let styledPrompt = responseMessageStyle.attributedStringWithText(prompt)
        let title =
        NSAttributedString.joinInNaturalLayout(before: iconText, after: styledPrompt)
        UIView.performWithoutAnimation {
            cell.commentButton.setAttributedTitle(title, forState: .Normal)
        }
        
        
        let voteCount = responses[indexPath.row].voteCount
        let voted = responses[indexPath.row].voted
        cell.commentButton.row = indexPath.row
        
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Post):
            return cellForPostAtIndexPath(indexPath)
        case .Some(.Responses):
            return cellForResponseAtIndexPath(indexPath)
        case .None:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }

    private func updateVoteText(button: DiscussionCellButton, voteCount: Int, voted: Bool) {
        // TODO: show upvote and downvote depending on voted?
        let buttonText = NSAttributedString.joinInNaturalLayout(
            before: Icon.UpVote.attributedTextWithStyle(cellButtonStyle),
            after: cellButtonStyle.attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("VOTE", Float(voteCount), nil), parameters: ["count": Float(voteCount)])))
        
        UIView.performWithoutAnimation {
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let buttonText = NSAttributedString.joinInNaturalLayout(
            before: Icon.FollowStar.attributedTextWithStyle(cellButtonStyle),
            after: cellButtonStyle.attributedStringWithText(OEXLocalizedString(following ? "DISCUSSION_UNFOLLOW" : "DISCUSSION_FOLLOW", nil)))
        button.setAttributedTitle(buttonText, forState:.Normal)
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if TableSection(rawValue: indexPath.section) != .Post {
            cell.backgroundColor = UIColor.clearColor()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Post):
            return 200.0
        case .Some(.Responses):
            return 210.0
        case .None:
            assert(false, "Unknown table section")
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO
    }
    
}