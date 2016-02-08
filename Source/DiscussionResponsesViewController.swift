//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GeneralPadding: CGFloat = 8.0

private let cellButtonStyle = OEXTextStyle(weight:.Normal, size:.Small, color: OEXStyles.sharedStyles().neutralDark())
private let cellIconSelectedStyle = cellButtonStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())
private let responseCountStyle = OEXTextStyle(weight:.Normal, size:.Base, color:OEXStyles.sharedStyles().primaryBaseColor())
private let responseMessageStyle = OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralBase())

class DiscussionCellButton: UIButton {
    var indexPath: NSIndexPath?
    
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
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorLineHeightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .None
        
        for (button, icon, text) in [
            (voteButton, Icon.UpVote, nil as String?),
            (followButton, Icon.FollowStar, Strings.discussionFollow),
            (reportButton, Icon.ReportFlag, Strings.discussionReport)
            ]
           
        {
            let buttonText = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(cellButtonStyle, inline: true),
                cellButtonStyle.attributedStringWithText(text ?? "")])
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
        
        separatorLine.backgroundColor = OEXStyles.sharedStyles().standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .Leading
        followButton.localizedHorizontalContentAlignment = .Center
        reportButton.localizedHorizontalContentAlignment = .Trailing
        authorButton.localizedHorizontalContentAlignment = .Leading
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
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var endorsedByButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .None
        
        for (button, icon, text) in [
            (reportButton, Icon.ReportFlag, Strings.discussionReport)]
        {
            let iconString = icon.attributedTextWithStyle(cellButtonStyle, inline: true)
            let buttonText = NSAttributedString.joinInNaturalLayout([iconString,
                cellButtonStyle.attributedStringWithText(text)])
            button.setAttributedTitle(buttonText, forState:.Normal)
        }
        
        var endorsedTextStyle : OEXTextStyle {
            return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
        }
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(endorsedTextStyle, inline : true)
        let endorsedText = endorsedTextStyle.attributedStringWithText(Strings.answer)
        
        endorsedLabel.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        
        commentBox.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
        
        separatorLine.backgroundColor = OEXStyles.sharedStyles().standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .Leading
        reportButton.localizedHorizontalContentAlignment = .Trailing
        authorButton.localizedHorizontalContentAlignment = .Leading
        endorsedByButton.localizedHorizontalContentAlignment = .Leading
        
        containerView.applyBorderStyle(BorderStyle())
    }
    
    var endorsed : Bool = false {
        didSet {
            endorsedLabel.hidden = !endorsed
            endorsedByButton.hidden = !endorsed
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
                make.top.equalTo(containerView).offset(StandardVerticalMargin)
            })
        }
        super.updateConstraints()
        
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate {
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider>

    enum TableSection : Int {
        case Post = 0
        case EndorsedResponses = 1
        case Responses = 2
    }
    
    var environment: Environment!
    var courseID: String!
    var threadID: String!
    
    var loadController : LoadStateViewController?
    var paginationController : TablePaginationController<DiscussionComment>?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    
    private let addResponseButton = UIButton(type: .System)
    private var responses : [DiscussionComment]  = []
    private var endorsedResponses : [DiscussionComment]  = []
    var thread: DiscussionThread?
    var postFollowing = false

    func loadedThread(thread : DiscussionThread) {
        let hadThread = self.thread != nil
        self.thread = thread
        if !hadThread {
            self.initializePaginator()
        }
        let styles = OEXStyles.sharedStyles()
        let footerStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralWhite())
        
        let icon = postClosed ? Icon.Closed : Icon.Create
        let text = postClosed ? Strings.responsesClosed : Strings.addAResponse
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(footerStyle.withSize(.XSmall)),
            footerStyle.attributedStringWithText(text)])
        
        addResponseButton.setAttributedTitle(buttonTitle, forState: .Normal)
        addResponseButton.backgroundColor = postClosed ? styles.neutralBase() : styles.primaryXDarkColor()
        addResponseButton.enabled = !postClosed
        
        addResponseButton.oex_removeAllActions()
        if !thread.closed {
            addResponseButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
                if let owner = self, thread = owner.thread {
                    owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, context: .Thread(thread))
                }
                }, forEvents: UIControlEvents.TouchUpInside)
        }
        
        self.navigationItem.title = navigationItemTitleForThread(thread)
        
        tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) , withRowAnimation: .Fade)
    }
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    var postBodyTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    var responseBodyTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralBase())

    }
    
    override func viewDidLoad() {
        assert(environment != nil)
        assert(courseID != nil)
        
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        tableView.backgroundColor = UIColor.clearColor()
        tableView.delegate = self
        tableView.dataSource = self
        
        loadController = LoadStateViewController()
        
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
        
        loadThread()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func navigationItemTitleForThread(thread : DiscussionThread) -> String {
        switch thread.type {
        case .Discussion:
            return Strings.discussion
        case .Question:
            return thread.hasEndorsed ? Strings.answeredQuestion : Strings.unansweredQuestion
        }
    }
    
    private var postClosed : Bool {
        return thread?.closed ?? false
    }
    
    private func markThreadAsRead() {
        if let thread = thread {
            let apiRequest = DiscussionAPI.readThread(true, threadID: thread.threadID)
            
            self.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                if let thread = result.data {
                    self?.loadedThread(thread)
                    self?.tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) , withRowAnimation: .Fade)
                }
            }
        }
    }
    
    private func loadThread() {
        let updatePostRequest = DiscussionAPI.getThreadByID(threadID)
        self.environment.networkManager.taskForRequest(updatePostRequest) {[weak self] response in
            if let postThread = response.data {
                self?.loadedThread(postThread)
                self?.markThreadAsRead()
            }
        }
    }
    
    private func initializePaginator() {
        
        if let thread = thread {
            postFollowing = thread.following
            
            let paginator = UnwrappedNetworkPaginator(networkManager: self.environment.networkManager) { page in
                return DiscussionAPI.getResponses(thread.threadID, threadType: thread.type, endorsedOnly: false, pageNumber: page)
            }
            
            paginationController = TablePaginationController (paginator: paginator, tableView: self.tableView)
            
            loadEndorsedResponses()
            loadResponses()
        }
    }
    
    private func loadEndorsedResponses() {
        if let thread = thread {
            // its assumption always there shoud be 1 page for endorsed responses
            let apiRequest = DiscussionAPI.getResponses(thread.threadID, threadType: .Question, endorsedOnly: true, pageNumber: 1)
            
            self.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                if let responses = result.data {
                    self?.endorsedResponses = responses
                    self?.tableView.reloadSections(NSIndexSet(index: TableSection.EndorsedResponses.rawValue) , withRowAnimation: .Fade)
                }
            }
        }
    }
    
    private func loadResponses() {
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .Loaded
                self?.responses = responses
                self?.tableView.reloadSections(NSIndexSet(index: TableSection.Responses.rawValue) , withRowAnimation: .Fade)
            }, failure: { [weak self] (error) -> Void in
                self?.loadController?.state = LoadState.failed(error)
            })
        
        paginationController?.loadMore()
    }
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, indexPath = button.indexPath {
            
            let aResponse:DiscussionComment?
            
            switch TableSection(rawValue: indexPath.section) {
            case .Some(.EndorsedResponses):
                aResponse = endorsedResponses[indexPath.row]
            case .Some(.Responses):
                aResponse = responses[indexPath.row]
            default:
                aResponse = nil
            }
            
            if let response = aResponse {
                if response.childCount == 0{
                    if !postClosed {
                        environment.router?.showDiscussionNewCommentFromController(self, courseID: courseID, context: .Comment(response))
                    }
                } else {
                    environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, response: response, closed : postClosed)
                }
            }
        }
    }
    
    // Mark - tableview delegate methods

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section) {
        case .Some(.Post): return 1
        case .Some(.EndorsedResponses): return endorsedResponses.count
        case .Some(.Responses): return responses.count
        case .None:
            assert(false, "Unknown table section")
            return 0
        }
    }
    
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Post):
            cell.backgroundColor = UIColor.whiteColor()
        case .Some(.EndorsedResponses):
            cell.backgroundColor = UIColor.clearColor()
        case .Some(.Responses):
            cell.backgroundColor = UIColor.clearColor()
        default:
            assert(false, "Unknown table section")
        }
    }
    
    func applyThreadToCell(cell: DiscussionPostCell) -> UITableViewCell {
        if let thread = self.thread {
            var authorLabelAttributedStrings = [NSAttributedString]()
            
            cell.titleLabel.attributedText = titleTextStyle.attributedStringWithText(thread.title)
            cell.bodyTextLabel.attributedText = postBodyTextStyle.attributedStringWithText(thread.rawBody)
            
            let visibilityString : String
            if let cohortName = thread.groupName {
                visibilityString = Strings.postVisibility(cohort: cohortName)
            }
            else {
                visibilityString = Strings.postVisibilityEveryone
            }
            
            
            cell.visibilityLabel.attributedText = infoTextStyle.attributedStringWithText(visibilityString)
            
            if postClosed {
                authorLabelAttributedStrings.append(Icon.Closed.attributedTextWithStyle(infoTextStyle, inline: true))
            }
            
            if (thread.pinned) {
                authorLabelAttributedStrings.append(Icon.Pinned.attributedTextWithStyle(infoTextStyle, inline: true))
            }
            
            authorLabelAttributedStrings.append(thread.authorLabelForTextStyle(infoTextStyle))
            
            cell.authorButton.setAttributedTitle(NSAttributedString.joinInNaturalLayout(authorLabelAttributedStrings), forState: .Normal)
            let profilesEnabled = OEXConfig.sharedConfig().shouldEnableProfiles()
            cell.authorButton.enabled = profilesEnabled
            if profilesEnabled {
                cell.authorButton.oex_removeAllActions()
                cell.authorButton.oex_addAction({ [weak self] _ in
                    self?.environment.router?.showProfileForUsername(self, username: thread.author, editable: false)
                    }, forEvents: .TouchUpInside)
            }

            if let responseCount = thread.responseCount {
                let icon = Icon.Comment.attributedTextWithStyle(infoTextStyle)
                let countLabelText = infoTextStyle.attributedStringWithText(Strings.response(count: responseCount))
                
                let labelText = NSAttributedString.joinInNaturalLayout([icon,countLabelText])
                cell.responseCountLabel.attributedText = labelText
            }
            else {
                cell.responseCountLabel.attributedText = nil
            }
            
            updateVoteText(cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
            updateFollowText(cell.followButton, following: thread.following)
        }
        
        // vote a post (thread) - User can only vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, button = action as? DiscussionCellButton, thread = owner.thread {
                button.enabled = false
                
                let apiRequest = DiscussionAPI.voteThread(thread.voted, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                    if let thread: DiscussionThread = result.data {
                        self?.loadedThread(thread)
                    }
                    button.enabled = true
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        // follow a post (thread) - User can only follow original post, not response or comment.
        cell.followButton.oex_removeAllActions()
        cell.followButton.oex_addAction({[weak self] (sender : AnyObject!) -> Void in
            if let owner = self, thread = owner.thread {
                let apiRequest = DiscussionAPI.followThread(owner.postFollowing, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread: DiscussionThread = result.data {
                        owner.updateFollowText(cell.followButton, following: thread.following)
                        owner.postFollowing = thread.following
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        if let item = self.thread {
            updateVoteText(cell.voteButton, voteCount: item.voteCount, voted: item.voted)
            updateFollowText(cell.followButton, following: item.following)
            updateReportText(cell.reportButton, report: thread!.abuseFlagged)
        }
        
        // report (flag) a post (thread) - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, item = owner.thread {
                let apiRequest = DiscussionAPI.flagThread(!item.abuseFlagged, threadID: item.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread = result.data {
                        self?.thread?.abuseFlagged = thread.abuseFlagged
                        owner.updateReportText(cell.reportButton, report: thread.abuseFlagged)
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        return cell

    }
    
    func cellForResponseAtIndexPath(indexPath : NSIndexPath, response: DiscussionComment) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
        
        cell.bodyTextLabel.attributedText = responseBodyTextStyle.attributedStringWithText(response.rawBody)
        cell.authorButton.setAttributedTitle(response.authorLabelForTextStyle(infoTextStyle), forState: .Normal)
        cell.endorsedByButton.setAttributedTitle(response.endorsedLabelForTextStyle(infoTextStyle), forState: .Normal)
        
        let profilesEnabled = OEXConfig.sharedConfig().shouldEnableProfiles()
        cell.authorButton.enabled = profilesEnabled
        if profilesEnabled {
            cell.authorButton.oex_removeAllActions()
            cell.authorButton.oex_addAction({ [weak self] _ in
                OEXRouter.sharedRouter().showProfileForUsername(self, username: response.author, editable: false)
                }, forEvents: .TouchUpInside)
            
            if response.endorsed {
                cell.endorsedByButton.oex_removeAllActions()
                cell.endorsedByButton.oex_addAction({ [weak self] _ in
                    OEXRouter.sharedRouter().showProfileForUsername(self, username: response.endorsedBy!, editable: false)
                    }, forEvents: .TouchUpInside)
            }
        }

        let prompt : String
        let icon : Icon
        
        if response.childCount == 0 {
            prompt = postClosed ? Strings.commentsClosed : Strings.addAComment
            icon = postClosed ? Icon.Closed : Icon.Comment
        }
        else {
            prompt = Strings.commentsToResponse(count: response.childCount)
            icon = Icon.Comment
        }
        
        
        let iconText = icon.attributedTextWithStyle(responseMessageStyle, inline : true)
        let styledPrompt = responseMessageStyle.attributedStringWithText(prompt)
        let title =
        NSAttributedString.joinInNaturalLayout([iconText,styledPrompt])
        UIView.performWithoutAnimation {
            cell.commentButton.setAttributedTitle(title, forState: .Normal)
        }
        
        
        let voteCount = response.voteCount
        let voted = response.voted
        cell.commentButton.indexPath = indexPath

        updateVoteText(cell.voteButton, voteCount: voteCount, voted: voted)
        updateReportText(cell.reportButton, report: response.abuseFlagged)
        
        cell.voteButton.indexPath = indexPath
        // vote/unvote a response - User can vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, button = action as? DiscussionCellButton, indexPath = button.indexPath {
                let voted = owner.responses[indexPath.row].voted
                let apiRequest = DiscussionAPI.voteResponse(voted, responseID: owner.responses[indexPath.row].commentID)

                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let response: DiscussionComment = result.data {
                        owner.responses[indexPath.row].voted = response.voted
                        let voteCount = response.voteCount
                        owner.responses[indexPath.row].voteCount = voteCount
                        owner.updateVoteText(cell.voteButton, voteCount: voteCount, voted: response.voted)
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        
        cell.reportButton.indexPath = indexPath
        // report (flag)/unflag a response - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, button = action as? DiscussionCellButton, indexPath = button.indexPath {
                let apiRequest = DiscussionAPI.flagComment(!owner.responses[indexPath.row].abuseFlagged, commentID: owner.responses[indexPath.row].commentID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let comment = result.data {
                        owner.responses[indexPath.row].abuseFlagged = comment.abuseFlagged
                        owner.updateReportText(cell.reportButton, report: comment.abuseFlagged)
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        cell.endorsed = response.endorsed
        return cell

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Post):
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
            return applyThreadToCell(cell)
        case .Some(.EndorsedResponses):
            return cellForResponseAtIndexPath(indexPath, response: endorsedResponses[indexPath.row])
        case .Some(.Responses):
            return cellForResponseAtIndexPath(indexPath, response: responses[indexPath.row])
        case .None:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }

    private func updateVoteText(button: DiscussionCellButton, voteCount: Int, voted: Bool) {
        // TODO: show upvote and downvote depending on voted?
        let iconStyle = voted ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([
            Icon.UpVote.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(Strings.vote(count: voteCount))])
        
        button.setAttributedTitle(buttonText, forState:.Normal)
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let iconStyle = following ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.FollowStar.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(following ? Strings.discussionUnfollow : Strings.discussionFollow )])
        button.setAttributedTitle(buttonText, forState:.Normal)
    }
    
    private func updateReportText(button: DiscussionCellButton, report: Bool) {
        let iconStyle = report ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.ReportFlag.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(report ? Strings.discussionUnreport : Strings.discussionReport )])
        button.setAttributedTitle(buttonText, forState:.Normal)
    }
    
    // MARK- DiscussionNewCommentViewControllerDelegate method
    
    func newCommentController(controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        
        switch controller.currentContext() {
        case .Thread(_):
            self.responses.append(comment)
        case .Comment(_):
            for i in 0..<responses.count {
                
                if responses[i].commentID == comment.parentID {
                    responses[i].childCount += 1
                }
            }
        }
        
        self.tableView.reloadData()
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
    var createdAt : NSDate? { get }
    var author : String { get }
    var authorLabel : String? { get }
}

protocol EndorsedLabelProtocol {
    var endorsedAt : NSDate? { get }
    var endorsedBy : String? { get }
    var endorsedByLabel : String? { get }
}


extension DiscussionComment : AuthorLabelProtocol {}
extension DiscussionComment : EndorsedLabelProtocol {}
extension DiscussionThread : AuthorLabelProtocol {}

extension AuthorLabelProtocol {
    func authorLabelForTextStyle(textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        if let displayDate = self.createdAt?.displayDate {
            attributedStrings.append(textStyle.attributedStringWithText(displayDate))
        }
        
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        if OEXConfig.sharedConfig().shouldEnableProfiles() {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
        }
        let byAuthor = Strings.byAuthorLowerCase(authorName: author)
        let byline = textStyle.attributedStringWithText(byAuthor).mutableCopy() as! NSMutableAttributedString
        byline.setAttributes(highlightStyle.attributes, range: (byAuthor as NSString).rangeOfString(author)) //okay because edx doesn't support fancy chars in usernames
        attributedStrings.append(byline)
        
        if let authorLabel = self.authorLabel {
            attributedStrings.append(textStyle.attributedStringWithText(authorLabel))
        }
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}

extension EndorsedLabelProtocol {
    func endorsedLabelForTextStyle(textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        attributedStrings.append(textStyle.attributedStringWithText(Strings.markedAnswer))
        
        if let displayDate = endorsedAt?.displayDate {
            attributedStrings.append(textStyle.attributedStringWithText(displayDate))
        }
        
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        if OEXConfig.sharedConfig().shouldEnableProfiles() {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
        }
        
        if let endorsed = endorsedBy {
            let byAuthor = Strings.byAuthorLowerCase(authorName: endorsed)
            let byline = textStyle.attributedStringWithText(byAuthor).mutableCopy() as! NSMutableAttributedString
            byline.setAttributes(highlightStyle.attributes, range: (byAuthor as NSString).rangeOfString(endorsed)) //okay because edx doesn't support fancy chars in usernames
            attributedStrings.append(byline)
        }
        
        
        if let authorLabel = endorsedByLabel {
            attributedStrings.append(textStyle.attributedStringWithText(authorLabel))
        }
        
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}


