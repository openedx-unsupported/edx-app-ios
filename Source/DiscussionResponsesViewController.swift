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
            case .Post(_): return nil
            case let .Response(item): return item.responseID
        }
    }
    
    var title: String? {
        switch self {
            case let .Post(item): return item.title
            case .Response(_): return nil
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
    
    var isEndorsed : Bool {
        switch self {
        case .Post(_): return false //A post itself can never be endorsed
        case let .Response(item): return item.endorsed
        }
    }
    
    //We can make this enum conform to AuthorLabelProtocol when Swift improves
    func authorLabelForTextStyle(textStyle : OEXTextStyle) -> NSAttributedString {
        switch self {
        case let .Post(item) : return item.authorLabelForTextStyle(textStyle)
        case let .Response(item) : return item.authorLabelForTextStyle(textStyle)
        }
    }
}

public struct DiscussionResponseItem {
    public let body: String
    public let author: String
    public let createdAt: NSDate
    public var voteCount: Int
    public let responseID: String
    public let threadID: String
    public let flagged: Bool
    public var voted: Bool
    public let children: [DiscussionComment]
    public let commentCount : Int
    public let endorsed : Bool
    public let authorLabel : String?
    
    public init(
        body: String,
        author: String,
        createdAt: NSDate,
        voteCount: Int,
        responseID: String,
        threadID: String,
        flagged: Bool,
        voted: Bool,
        children: [DiscussionComment],
        commentCount : Int,
        endorsed : Bool,
        authorLabel : String?
        )
    {
        self.body = body
        self.author = author
        self.createdAt = createdAt
        self.voteCount = voteCount
        self.responseID = responseID
        self.threadID = threadID
        self.flagged = flagged
        self.voted = voted
        self.children = children
        self.commentCount = commentCount
        self.endorsed = endorsed
        self.authorLabel = authorLabel
    }
    
    //TODO: Use this initializer where possible
    public init?(comment : DiscussionComment) {
        guard let body = comment.rawBody,
            author = comment.author,
            createdAt = comment.createdAt,
            threadID = comment.threadId,
            children = comment.children else {
                return nil }
        
        let voteCount = comment.voteCount
        self.init(
            body: body,
            author: author,
            createdAt: createdAt,
            voteCount: voteCount,
            responseID: comment.commentID,
            threadID: threadID,
            flagged: comment.flagged,
            voted: comment.voted,
            children: children,
            commentCount: children.count,
            endorsed: comment.endorsed,
            authorLabel: comment.authorLabel
        )
    }
}

private let GeneralPadding: CGFloat = 8.0

private let cellButtonStyle = OEXTextStyle(weight:.Normal, size:.XSmall, color: OEXStyles.sharedStyles().neutralDark())
private let cellIconSelectedStyle = cellButtonStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())
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
    @IBOutlet private var authorButton: UIButton!
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
            let buttonText = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(cellButtonStyle, inline: true),
                cellButtonStyle.attributedStringWithText(text ?? "")])
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    private static let margin : CGFloat = 8.0
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var bodyTextLabel: UILabel!
    @IBOutlet private var authorButton: UIButton!
    @IBOutlet private var voteButton: DiscussionCellButton!
    @IBOutlet private var reportButton: DiscussionCellButton!
    @IBOutlet private var commentButton: DiscussionCellButton!
    @IBOutlet private var commentBox: UIView!
    @IBOutlet private var endorsedLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .None
        
        for (button, icon, text) in [
            (reportButton, Icon.ReportFlag, OEXLocalizedString("DISCUSSION_REPORT", nil))]
        {
            let iconString = icon.attributedTextWithStyle(cellButtonStyle, inline: true)
            let buttonText = NSAttributedString.joinInNaturalLayout([iconString,
                cellButtonStyle.attributedStringWithText(text)])
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
        
        var endorsedTextStyle : OEXTextStyle {
            return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().utilitySuccessBase())
        }
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(endorsedTextStyle, inline : true)
        let endorsedText = endorsedTextStyle.attributedStringWithText(OEXLocalizedString("ANSWER", nil))
        
        endorsedLabel.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        
        commentBox.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
    }
    
    var endorsed : Bool = false {
        didSet {
            let endorsedBorderStyle = OEXStyles.sharedStyles().endorsedPostBorderStyle
            let unendorsedBorderStyle = BorderStyle()
            let borderStyle = endorsed ?  endorsedBorderStyle : unendorsedBorderStyle
            containerView.applyBorderStyle(borderStyle)
            endorsedLabel.hidden = !endorsed
        }
    }
    
    override func updateConstraints() {
        if endorsed {
            bodyTextLabel.snp_updateConstraints(closure: { (make) -> Void in
                make.top.equalTo(endorsedLabel.snp_bottom)
            })
        }
        else {
            bodyTextLabel.snp_updateConstraints(closure: { (make) -> Void in
                make.top.equalTo(containerView).offset(8)
            })
        }
        super.updateConstraints()
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
    
    var loadController : LoadStateViewController?
    
    var networkPaginator : NetworkPaginator<DiscussionComment>?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    
    private let addResponseButton = UIButton(type: .System)
    private var responses : [DiscussionResponseItem]  = []
    var postItem: DiscussionPostItem?
    var postFollowing = false

    var postClosed : Bool = false {
        didSet {
            let styles = OEXStyles.sharedStyles()
            let footerStyle = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite())
            
            let icon = postClosed ? Icon.Closed : Icon.Create
            let text = postClosed ? OEXLocalizedString("RESPONSES_CLOSED", nil) : OEXLocalizedString("ADD_A_RESPONSE", nil)
            
            let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(footerStyle.withSize(.XSmall)),
                footerStyle.attributedStringWithText(text)])
            
            addResponseButton.setAttributedTitle(buttonTitle, forState: .Normal)
            addResponseButton.backgroundColor = postClosed ? styles.neutralBase() : styles.primaryXDarkColor()
            addResponseButton.enabled = !postClosed
            
            if !postClosed {
                addResponseButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
                    if let owner = self, item = owner.postItem {
                        owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, item: DiscussionItem.Post(item))
                    }
                    }, forEvents: UIControlEvents.TouchUpInside)
            }
            
        }
    }
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: self.environment.styles.neutralXDark())
    }
    
    var postBodyTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: self.environment.styles.neutralDark())
    }
    
    var responseBodyTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: self.environment.styles.neutralDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXXSmall, color: self.environment.styles.neutralBase())

    }
    
    override func viewDidLoad() {
        assert(environment != nil)
        assert(courseID != nil)
        
        super.viewDidLoad()
        
        self.navigationItem.title = OEXLocalizedString("DISCUSSION_POST", nil)
        self.view.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        loadController = LoadStateViewController(styles: self.environment.styles)

        postClosed = postItem?.closed ?? false
        
        addResponseButton.contentVerticalAlignment = .Center
        view.addSubview(addResponseButton)
        addResponseButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.sharedStyles().standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
            make.top.equalTo(tableView.snp_bottom)
        }
        
        tableView.estimatedRowHeight = 160.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        loadController?.setupInController(self, contentView: self.contentView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadInitialData()
        updatePostItem()
    }
    
    private func updatePostItem() {
        if let item = postItem {
            let updatePostRequest = DiscussionAPI.getThreadByID(item.threadID)
            self.environment.networkManager?.taskForRequest(updatePostRequest) {[weak self] thread in
                if let postThread = thread.data {
                    self?.postItem = DiscussionPostItem(thread: postThread, defaultThreadType: .Discussion)
                    self?.tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) , withRowAnimation: .Fade)
                }
            }
        }
    }
    
    private func loadInitialData() {
        if let item = postItem {
            postFollowing = item.following
            
            self.networkPaginator = NetworkPaginator(networkManager: self.environment.networkManager, paginatedFeed: item.unendorsedCommentsPaginatedFeed, tableView: self.tableView)
            
            switch item.type {
            case .Discussion:
                //Start loading data via the paginator
                loadPaginatedDataIfAvailable(removePrevious: true)
            case .Question:
                //Load the endorsed responses only at first
                //If there are no endorsed responses, load paginated data
                let endorsedCommentsRequest = DiscussionAPI.getResponses(item.threadID, threadType: item.type, markAsRead: true, endorsedOnly: true)
                self.environment.networkManager?.taskForRequest(endorsedCommentsRequest) {[weak self] result in
                    guard let responses : [DiscussionComment] = result.data where !responses.isEmpty else {
                        self?.loadPaginatedDataIfAvailable(removePrevious: true)
                        return
                    }
                    self?.updateResponses(responses, removeAll: true)
                }
                
            }
        }
    }
    
    func updateResponses(responses : [DiscussionComment], removeAll : Bool) {
            if removeAll {
                self.responses.removeAll(keepCapacity: true)
                if responses.isEmpty {
                    // TODO : Configure the empty state
                    //  self.loadController?.state = LoadState.Empty(icon: Icon?, message: String?, attributedMessage: NSAttributedString?, accessibilityMessage: String?)
                }

            }
        
            for response in responses {
                //Confusion with the name here because the backend treats Comments and Responses alike
                if let item = DiscussionResponseItem(comment: response) {
                    self.responses.append(item)
                }
            }
            self.tableView.reloadData()
            self.loadController?.state = .Loaded
    }
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, row = button.row {
            let response = responses[row]
            if response.children.count == 0 {
                if !postClosed {
                    environment.router?.showDiscussionNewCommentFromController(self, courseID: courseID, item: DiscussionItem.Response(response))
                }
            } else {
                environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, item: response, closed : postClosed)
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

            var authorLabelAttributedStrings = [NSAttributedString]()
            
            
            cell.titleLabel.attributedText = titleTextStyle.attributedStringWithText(item.title)
            cell.bodyTextLabel.attributedText = postBodyTextStyle.attributedStringWithText(item.body)
            
            let visibilityString : String
            if let cohortName = item.groupName {
                visibilityString = NSString.oex_stringWithFormat(OEXLocalizedString("POST_VISIBILITY", nil), parameters: ["cohort":cohortName]) as String
            }
            else {
                visibilityString = OEXLocalizedString("POST_VISIBILITY_EVERYONE", nil)
            }
            
            
            cell.visibilityLabel.attributedText = infoTextStyle.attributedStringWithText(visibilityString)
            
            if postClosed {
                authorLabelAttributedStrings.append(Icon.Closed.attributedTextWithStyle(infoTextStyle, inline: true))
            }
            
            if (item.pinned) {
                authorLabelAttributedStrings.append(Icon.Pinned.attributedTextWithStyle(infoTextStyle, inline: true))
            }
            
            authorLabelAttributedStrings.append(item.authorLabelForTextStyle(infoTextStyle))
            
            cell.authorButton.setAttributedTitle(NSAttributedString.joinInNaturalLayout(authorLabelAttributedStrings), forState: .Normal)
            let profilesEnabled = OEXConfig.sharedConfig().shouldEnableProfiles()
            cell.authorButton.enabled = profilesEnabled
            if profilesEnabled {
                cell.authorButton.oex_removeAllActions()
                cell.authorButton.oex_addAction({ [weak self] _ in
                    OEXRouter.sharedRouter().showProfileForUsername(self, username: item.author, editable: false)
                    }, forEvents: .TouchUpInside)
            }

            if let responseCount = item.responseCount {
                let icon = Icon.Comment.attributedTextWithStyle(infoTextStyle)
                let countLabelText = infoTextStyle.attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("RESPONSE", Float(responseCount), nil), parameters: ["count": Float(responseCount)]))
                
                let labelText = NSAttributedString.joinInNaturalLayout([icon,countLabelText])
                cell.responseCountLabel.attributedText = labelText
            }
            else {
                cell.responseCountLabel.attributedText = nil
            }
        }
        
        // vote a post (thread) - User can only vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, button = action as? DiscussionCellButton, item = owner.postItem {
                button.enabled = false
                
                let apiRequest = DiscussionAPI.voteThread(item.voted, threadID: item.threadID)
                
                owner.environment.networkManager?.taskForRequest(apiRequest) { result in
                    if let thread: DiscussionThread = result.data {
                        let voteCount = thread.voteCount
                        owner.updateVoteText(cell.voteButton, voteCount: voteCount, voted: thread.voted)
                        owner.postItem?.voteCount = voteCount
                        owner.postItem?.voted = thread.voted
                    }
                    button.enabled = true
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        // follow a post (thread) - User can only follow original post, not response or comment.
        cell.followButton.oex_removeAllActions()
        cell.followButton.oex_addAction({[weak self] (sender : AnyObject!) -> Void in
            if let owner = self, item = owner.postItem {
                let apiRequest = DiscussionAPI.followThread(owner.postFollowing, threadID: item.threadID)
                
                owner.environment.networkManager?.taskForRequest(apiRequest) { result in
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
            if let owner = self, item = owner.postItem {
                let apiRequest = DiscussionAPI.flagThread(item.flagged, threadID: item.threadID)
                
                owner.environment.networkManager?.taskForRequest(apiRequest) { result in
                    // TODO: update UI after API is done
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        return cell

    }
    
    func cellForResponseAtIndexPath(indexPath : NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
        let response = responses[indexPath.row]
        
        
        cell.bodyTextLabel.attributedText = responseBodyTextStyle.attributedStringWithText(response.body)
        
        let item = responses[indexPath.row]
        cell.authorButton.setAttributedTitle(item.authorLabelForTextStyle(infoTextStyle), forState: .Normal)
        let profilesEnabled = OEXConfig.sharedConfig().shouldEnableProfiles()
        cell.authorButton.enabled = profilesEnabled
        if profilesEnabled {
            cell.authorButton.oex_removeAllActions()
            cell.authorButton.oex_addAction({ [weak self] _ in
                OEXRouter.sharedRouter().showProfileForUsername(self, username: item.author, editable: false)
                }, forEvents: .TouchUpInside)
        }
        
        let commentCount = responses[indexPath.row].children.count

        let prompt : String
        let icon : Icon
        
        if commentCount == 0 {
            prompt = postClosed ? OEXLocalizedString("COMMENTS_CLOSED", nil) : OEXLocalizedString("ADD_A_COMMENT", nil)
            icon = postClosed ? Icon.Closed : Icon.Comment
        }
        else {
            prompt = NSString.oex_stringWithFormat(OEXLocalizedStringPlural("COMMENTS_TO_RESPONSE", Float(commentCount), nil), parameters: ["count": commentCount])
            icon = Icon.Comment
        }
        
        
        let iconText = icon.attributedTextWithStyle(responseMessageStyle)
        let styledPrompt = responseMessageStyle.attributedStringWithText(prompt)
        let title =
        NSAttributedString.joinInNaturalLayout([iconText,styledPrompt])
        UIView.performWithoutAnimation {
            cell.commentButton.setAttributedTitle(title, forState: .Normal)
        }
        
        
        let voteCount = response.voteCount
        let voted = response.voted
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

                owner.environment.networkManager?.taskForRequest(apiRequest) { result in
                    if let response: DiscussionComment = result.data {
                        owner.responses[row].voted = response.voted
                        let voteCount = response.voteCount
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
                
                owner.environment.networkManager?.taskForRequest(apiRequest) { result in
                    // result.error: Optional(Error Domain=org.edx.error Code=-100 "Unable to load course content.
                    // TODO: update UI after API is done
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        
        cell.endorsed = response.endorsed
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
        let iconStyle = voted ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.UpVote.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedStringPlural("VOTE", Float(voteCount), nil), parameters: ["count": Float(voteCount)]))])
        
        button.setAttributedTitle(buttonText, forState:.Normal)
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let iconStyle = following ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.FollowStar.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(OEXLocalizedString(following ? "DISCUSSION_UNFOLLOW" : "DISCUSSION_FOLLOW", nil))])
        button.setAttributedTitle(buttonText, forState:.Normal)
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if TableSection(rawValue: indexPath.section) != .Post {
            cell.backgroundColor = UIColor.clearColor()
        }
        
        if tableView.isLastRow(indexPath : indexPath) {
            loadPaginatedDataIfAvailable()
        }
    }
    
    private func loadPaginatedDataIfAvailable(removePrevious removePrevious : Bool = false) {
        self.networkPaginator?.loadDataIfAvailable() { [weak self] discussionResponses in
            if let responses = discussionResponses {
                self?.updateResponses(responses, removeAll: removePrevious)
            }
        }
    }
}
    


extension DiscussionPostItem {
    
    var unendorsedCommentsPaginatedFeed : PaginatedFeed<NetworkRequest<[DiscussionComment]>> {
            return PaginatedFeed() { i in
                return DiscussionAPI.getResponses(self.threadID, threadType: self.type, markAsRead: true, pageNumber: i)
        }
    }
}

extension NSDate {
    
    private var shouldDisplayTimeSpan : Bool {
        let currentDate = NSDate()
        return currentDate.daysFrom(self) < 7
    }
    
    public var displayDate : String {
        return shouldDisplayTimeSpan ? self.timeAgoSinceNow() : OEXDateFormatting.formatAsDateMonthYearStringWithDate(self)
    }
}

protocol AuthorLabelProtocol {
    var createdAt : NSDate {get}
    var author : String {get}
    var authorLabel : String? {get}
}

extension AuthorLabelProtocol {
    func authorLabelForTextStyle(textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        let displayDate = self.createdAt.displayDate
        attributedStrings.append(textStyle.attributedStringWithText(displayDate))
        
        let highlightStyle = textStyle.mutableCopy() as! OEXMutableTextStyle
        if OEXConfig.sharedConfig().shouldEnableProfiles() {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
        }
        let byAuthor = Strings.byAuthorLowerCase(author)
        let byline = textStyle.attributedStringWithText(byAuthor).mutableCopy() as! NSMutableAttributedString
        byline.setAttributes(highlightStyle.attributes, range: (byAuthor as NSString).rangeOfString(author)) //okay because edx doesn't support fancy chars in usernames
        attributedStrings.append(byline)
        
        
        if let authorLabel = self.authorLabel {
            attributedStrings.append(textStyle.attributedStringWithText(authorLabel))
        }
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}

extension DiscussionPostItem : AuthorLabelProtocol {
    
}

extension DiscussionResponseItem : AuthorLabelProtocol {
    
}


