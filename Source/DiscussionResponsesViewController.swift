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
    @IBOutlet private var endorsedByButton: UIButton!
    
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
    
    var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
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
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXConfigProvider, OEXAnalyticsProvider>

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
    private let responsesDataController = DiscussionResponsesDataController()
    var thread: DiscussionThread?
    var postFollowing = false
    private var areAnsweredResponsesLoaded: Bool = false

    func loadedThread(thread : DiscussionThread) {
        let hadThread = self.thread != nil
        self.thread = thread
        if !hadThread {
            areAnsweredResponsesLoaded = false
            loadResponses()
            logScreenEvent()
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
                    owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, thread: thread, context: .Thread(thread))
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
    
    private func logScreenEvent(){
        if let thread = thread {
            
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewThread, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, commentId: nil)
        }
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
    
    private func loadResponses() {
        if let thread = thread {
            if !areAnsweredResponsesLoaded &&  thread.type == .Question {
                // load answered responses
                loadAnsweredResponses()
            }
            else {
                loadUnansweredResponses()
            }
        }
    }
    
    private func loadAnsweredResponses() {
        
        guard let thread = thread else { return }
        
        postFollowing = thread.following
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getResponses(thread.threadID, threadType: thread.type, endorsedOnly: true, pageNumber: page)
        }
        
        paginationController = TablePaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .Loaded
                self?.responsesDataController.endorsedResponses = responses
                self?.tableView.reloadData()
                
                if self?.paginationController?.hasNext ?? false {
                    // load unanswered responses
                    self?.areAnsweredResponsesLoaded = true
                    self?.loadUnansweredResponses()
                }
                
            }, failure: { [weak self] (error) -> Void in
                self?.loadController?.state = LoadState.failed(error)
                
            })
        
        paginationController?.loadMore()
    }
    
    private func loadUnansweredResponses() {
        
        guard let thread = thread else { return }
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getResponses(thread.threadID, threadType: thread.type, pageNumber: page)
        }
        
        paginationController = TablePaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .Loaded
                self?.responsesDataController.responses = responses
                self?.tableView.reloadData()
            }, failure: { [weak self] (error) -> Void in
                // endorsed responses are loaded in separate request and also populated in different section
                if self?.responsesDataController.endorsedResponses.count <= 0 {
                    self?.loadController?.state = LoadState.failed(error)
                }
                else {
                    self?.loadController?.state = .Loaded
                }
            })
        
        paginationController?.loadMore()
    }
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, indexPath = button.indexPath {
            
            let aResponse:DiscussionComment?
            
            switch TableSection(rawValue: indexPath.section) {
            case .Some(.EndorsedResponses):
                aResponse = responsesDataController.endorsedResponses[indexPath.row]
            case .Some(.Responses):
                aResponse = responsesDataController.responses[indexPath.row]
            default:
                aResponse = nil
            }
            
            if let response = aResponse {
                if response.childCount == 0{
                    if !postClosed {
                        guard let thread = thread else { return }
                        
                        environment.router?.showDiscussionNewCommentFromController(self, courseID: courseID, thread:thread, context: .Comment(response))
                    }
                } else {
                    guard let thread = thread else { return }
                    
                    environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, response: response, closed : postClosed, thread: thread)
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
        case .Some(.EndorsedResponses): return responsesDataController.endorsedResponses.count
        case .Some(.Responses): return responsesDataController.responses.count
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
            
            authorLabelAttributedStrings.append(thread.formattedUserLabel(infoTextStyle))
            
            cell.authorButton.setAttributedTitle(NSAttributedString.joinInNaturalLayout(authorLabelAttributedStrings), forState: .Normal)
            let profilesEnabled = self.environment.config.shouldEnableProfiles()
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
        cell.authorButton.setAttributedTitle(response.formattedUserLabel(infoTextStyle), forState: .Normal)
        
        if let thread = thread {
            cell.endorsedByButton.setAttributedTitle(response.formattedUserLabel(response.endorsedBy, date: response.endorsedAt,label: response.endorsedByLabel ,endorsedLabel: true, threadType: thread.type, textStyle: infoTextStyle), forState: .Normal)
        }
        
        let profilesEnabled = self.environment.config.shouldEnableProfiles()
        cell.authorButton.enabled = profilesEnabled
        if profilesEnabled {
            cell.authorButton.oex_removeAllActions()
            cell.authorButton.oex_addAction({ [weak self] _ in
                self?.environment.router?.showProfileForUsername(self, username: response.author, editable: false)
                }, forEvents: .TouchUpInside)
            
            if response.endorsed {
                cell.endorsedByButton.oex_removeAllActions()
                cell.endorsedByButton.oex_addAction({ [weak self] _ in
                    
                    guard let endorsedBy = response.endorsedBy else { return }
                    
                    self?.environment.router?.showProfileForUsername(self, username: endorsedBy, editable: false)
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
                
                let voted = owner.responsesDataController.responses[indexPath.row].voted
                let apiRequest = DiscussionAPI.voteResponse(voted, responseID: owner.responsesDataController.responses[indexPath.row].commentID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let response: DiscussionComment = result.data {
                        owner.responsesDataController.responses[indexPath.row].voted = response.voted
                        let voteCount = response.voteCount
                        owner.responsesDataController.responses[indexPath.row].voteCount = voteCount
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
                let apiRequest = DiscussionAPI.flagComment(!owner.responsesDataController.responses[indexPath.row].abuseFlagged, commentID: owner.responsesDataController.responses[indexPath.row].commentID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let comment = result.data {
                        owner.responsesDataController.responses[indexPath.row].abuseFlagged = comment.abuseFlagged
                        owner.updateReportText(cell.reportButton, report: comment.abuseFlagged)
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        cell.endorsed = response.endorsed
        
        if let thread = thread {
            DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
        }
        
        return cell

    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Post):
            let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionPostCell.identifier, forIndexPath: indexPath) as! DiscussionPostCell
            return applyThreadToCell(cell)
        case .Some(.EndorsedResponses):
            return cellForResponseAtIndexPath(indexPath, response: responsesDataController.endorsedResponses[indexPath.row])
        case .Some(.Responses):
            return cellForResponseAtIndexPath(indexPath, response: responsesDataController.responses[indexPath.row])
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
            self.responsesDataController.responses.append(comment)
        case .Comment(_):
            responsesDataController.addedChildComment(comment)
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


extension DiscussionComment : AuthorLabelProtocol {}
extension DiscussionThread : AuthorLabelProtocol {}

extension AuthorLabelProtocol {
    
    func formattedUserLabel(textStyle: OEXTextStyle) -> NSAttributedString {
        return formattedUserLabel(author, date: createdAt, label: authorLabel, threadType: nil, textStyle: textStyle)
    }
    
    func formattedUserLabel(name: String?, date: NSDate?, label: String?, endorsedLabel:Bool = false, threadType:DiscussionThreadType?, textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        if let threadType = threadType {
            switch threadType {
            case .Question where endorsedLabel:
                attributedStrings.append(textStyle.attributedStringWithText(Strings.markedAnswer))
            case .Discussion where endorsedLabel:
                attributedStrings.append(textStyle.attributedStringWithText(Strings.endorsed))
            default: break
            }
        }
        
        if let displayDate = date {
            attributedStrings.append(textStyle.attributedStringWithText(displayDate.displayDate))
        }
        
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        if OEXConfig.sharedConfig().shouldEnableProfiles() {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
        }
        
        if let username = name {
            
            let formattedUserName = highlightStyle.attributedStringWithText(username)
            
            let byAuthor =  textStyle.apply(Strings.byAuthorLowerCase) (formattedUserName)
            
            attributedStrings.append(byAuthor)
        }
        
        if let authorLabel = label {
            attributedStrings.append(textStyle.attributedStringWithText(authorLabel))
        }
        
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}
