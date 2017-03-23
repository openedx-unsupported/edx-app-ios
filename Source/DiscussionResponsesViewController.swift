//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GeneralPadding: CGFloat = 8.0

private let cellButtonStyle = OEXTextStyle(weight:.Normal, size:.Base, color: OEXStyles.sharedStyles().neutralDark())
private let cellIconSelectedStyle = cellButtonStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())
private let responseMessageStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
private let disabledCommentStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBase())

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
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
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
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
    }
    
    func setAccessibility(thread: DiscussionThread) {
        
        var accessibilityString = ""
        let sentenceSeparator = ", "
        
        if let title = thread.title {
            accessibilityString.appendContentsOf(title + sentenceSeparator)
        }
        
        if let body = thread.rawBody {
            accessibilityString.appendContentsOf(body + sentenceSeparator)
        }
        
        if let date = dateLabel.text {
            accessibilityString.appendContentsOf(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.appendContentsOf(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if let visibility = visibilityLabel.text {
            accessibilityString.appendContentsOf(visibility)
        }
        
        if let responseCount = responseCountLabel.text {
            accessibilityString.appendContentsOf(responseCount)
        }
        
        self.accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}

class DiscussionResponseCell: UITableViewCell {
    static let identifier = "DiscussionResponseCell"
    
    private static let margin : CGFloat = 8.0
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var bodyTextView: UITextView!
    @IBOutlet private var authorButton: UIButton!
    @IBOutlet private var voteButton: DiscussionCellButton!
    @IBOutlet private var reportButton: DiscussionCellButton!
    @IBOutlet private var commentButton: DiscussionCellButton!
    @IBOutlet private var commentBox: UIView!
    @IBOutlet private var endorsedLabel: UILabel!
    @IBOutlet private var separatorLine: UIView!
    @IBOutlet private var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var endorsedByButton: UIButton!
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
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
        
        accessibilityTraits = UIAccessibilityTraitHeader
        bodyTextView.isAccessibilityElement = false
        endorsedByButton.isAccessibilityElement = false
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
        if endorsedByButton.hidden {
            bodyTextView.snp_updateConstraints(closure: { (make) in
                make.bottom.equalTo(separatorLine.snp_top).offset(-StandardVerticalMargin)
            })
        }
        
        super.updateConstraints()
        
    }
    
    func setAccessibility(response: DiscussionComment) {
        
        var accessibilityString = ""
        let sentenceSeparator = ", "
        
        let body = bodyTextView.attributedText.string
        accessibilityString.appendContentsOf(body + sentenceSeparator)
        
        if let date = dateLabel.text {
            accessibilityString.appendContentsOf(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.appendContentsOf(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if endorsedByButton.hidden == false {
            if let endorsed = endorsedByButton.attributedTitleForState(.Normal)?.string  {
                accessibilityString.appendContentsOf(endorsed + sentenceSeparator)
            }
        }
        
        if response.childCount > 0 {
            accessibilityString.appendContentsOf(Strings.commentsToResponse(count: response.childCount))
        }
        
        self.accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate, DiscussionCommentsViewControllerDelegate, InterfaceOrientationOverriding {
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, OEXConfigProvider, OEXAnalyticsProvider>

    enum TableSection : Int {
        case Post = 0
        case EndorsedResponses = 1
        case Responses = 2
    }
    
    var environment: Environment!
    var courseID: String!
    var threadID: String!
    var isDiscussionBlackedOut: Bool = false
    
    var loadController : LoadStateViewController?
    var paginationController : PaginationController<DiscussionComment>?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    
    private let addResponseButton = UIButton(type: .System)
    private let responsesDataController = DiscussionResponsesDataController()
    var thread: DiscussionThread?
    var postFollowing = false

    func loadedThread(thread : DiscussionThread) {
        let hadThread = self.thread != nil
        self.thread = thread
        if !hadThread {
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
        
        let postingEnabled = (postClosed || isDiscussionBlackedOut)
        addResponseButton.backgroundColor = postingEnabled ? styles.neutralBase() : styles.primaryXDarkColor()
        addResponseButton.enabled = !postingEnabled
        
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
    
    var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())

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
        
        loadController?.setupInController(self, contentView: contentView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        markThreadAsRead()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    private func logScreenEvent(){
        if let thread = thread {
            
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewThread, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil)
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
        let apiRequest = DiscussionAPI.readThread(true, threadID: threadID)
        self.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            if let thread = result.data {
                self?.loadedThread(thread)
                self?.tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) , withRowAnimation: .Fade)
            }
        }
    }
    
    private func loadResponses() {
        if let thread = thread {
            if thread.type == .Question {
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
            return DiscussionAPI.getResponses(self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, endorsedOnly: true, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .Loaded
                self?.responsesDataController.endorsedResponses = responses
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                if self?.paginationController?.hasNext ?? false { }
                else {
                    // load unanswered responses
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
            return DiscussionAPI.getResponses(self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, pageNumber: page)
        }
        
        paginationController = PaginationController (paginator: paginator, tableView: self.tableView)
        
        paginationController?.stream.listen(self, success:
            { [weak self] responses in
                self?.loadController?.state = .Loaded
                self?.responsesDataController.responses = responses
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
                
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
                    
                    environment.router?.showDiscussionCommentsFromViewController(self, courseID : courseID, response: response, closed : postClosed, thread: thread, isDiscussionBlackedOut: isDiscussionBlackedOut)
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
            cell.titleLabel.attributedText = titleTextStyle.attributedStringWithText(thread.title)
            
            cell.bodyTextLabel.attributedText = detailTextStyle.attributedStringWithText(thread.rawBody)
            
            let visibilityString : String
            if let cohortName = thread.groupName {
                visibilityString = Strings.postVisibility(cohort: cohortName)
            }
            else {
                visibilityString = Strings.postVisibilityEveryone
            }
            cell.visibilityLabel.attributedText = infoTextStyle.attributedStringWithText(visibilityString)
            
            DiscussionHelper.styleAuthorDetails(thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)

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
                    button.enabled = true
                    
                    if let thread: DiscussionThread = result.data {
                        self?.loadedThread(thread)
                        owner.updateVoteText(cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
                    }
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                    }
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
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
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
                    else {
                        self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                    }
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        if let thread = self.thread {
            cell.setAccessibility(thread)
        }
        
        
        return cell

    }
    
    func cellForResponseAtIndexPath(indexPath : NSIndexPath, response: DiscussionComment) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(DiscussionResponseCell.identifier, forIndexPath: indexPath) as! DiscussionResponseCell
        
        cell.bodyTextView.attributedText = detailTextStyle.markdownStringWithText(response.renderedBody)
        
        if let thread = thread {
            let formatedTitle = response.formattedUserLabel(response.endorsedBy, date: response.endorsedAt,label: response.endorsedByLabel ,endorsedLabel: true, threadType: thread.type, textStyle: infoTextStyle)
            
            cell.endorsedByButton.setAttributedTitle(formatedTitle, forState: .Normal)
            
            cell.endorsedByButton.snp_updateConstraints(closure: { (make) in
                make.width.equalTo(formatedTitle.singleLineWidth() + StandardHorizontalMargin)
            })
        }
        
        DiscussionHelper.styleAuthorDetails(response.author, authorLabel: response.authorLabel, createdAt: response.createdAt, hasProfileImage: response.hasProfileImage, imageURL: response.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)
        
        DiscussionHelper.styleAuthorProfileImageView(cell.authorProfileImage)
        
        let profilesEnabled = self.environment.config.profilesEnabled
        
        if profilesEnabled && response.endorsed {
            cell.endorsedByButton.oex_removeAllActions()
            cell.endorsedByButton.oex_addAction({ [weak self] _ in
                
                guard let endorsedBy = response.endorsedBy else { return }
                
                self?.environment.router?.showProfileForUsername(self, username: endorsedBy, editable: false)
                }, forEvents: .TouchUpInside)
        }

        let prompt : String
        let icon : Icon
        let commentStyle : OEXTextStyle
        
        if response.childCount == 0 {
            prompt = postClosed ? Strings.commentsClosed : Strings.addAComment
            icon = postClosed ? Icon.Closed : Icon.Comment
            commentStyle = isDiscussionBlackedOut ? disabledCommentStyle : responseMessageStyle
            cell.commentButton.enabled = !isDiscussionBlackedOut
        }
        else {
            prompt = Strings.commentsToResponse(count: response.childCount)
            icon = Icon.Comment
            commentStyle = responseMessageStyle
        }
        
        let iconText = icon.attributedTextWithStyle(commentStyle, inline : true)
        let styledPrompt = commentStyle.attributedStringWithText(prompt)
        let title = NSAttributedString.joinInNaturalLayout([iconText,styledPrompt])
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
            
            let apiRequest = DiscussionAPI.voteResponse(response.voted, responseID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment: DiscussionComment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment)
                    self?.updateVoteText(cell.voteButton, voteCount: comment.voteCount, voted: comment.voted)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        cell.reportButton.indexPath = indexPath
        // report (flag)/unflag a response - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            let apiRequest = DiscussionAPI.flagComment(!response.abuseFlagged, commentID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment)
                    
                    self?.updateReportText(cell.reportButton, report: comment.abuseFlagged)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        cell.endorsed = response.endorsed
        
        if let thread = thread {
            DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            cell.setAccessibility(response)
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
        button.accessibilityHint = voted ? Strings.Accessibility.discussionUnvoteHint : Strings.Accessibility.discussionVoteHint
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let iconStyle = following ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.FollowStar.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(following ? Strings.discussionUnfollow : Strings.discussionFollow )])
        button.setAttributedTitle(buttonText, forState:.Normal)
        button.accessibilityHint = following ? Strings.Accessibility.discussionUnfollowHint : Strings.Accessibility.discussionFollowHint
    }
    
    private func updateReportText(button: DiscussionCellButton, report: Bool) {
        let iconStyle = report ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout([Icon.ReportFlag.attributedTextWithStyle(iconStyle, inline : true),
            cellButtonStyle.attributedStringWithText(report ? Strings.discussionUnreport : Strings.discussionReport )])
        button.setAttributedTitle(buttonText, forState:.Normal)
        button.accessibilityHint = report ? Strings.Accessibility.discussionUnreportHint : Strings.Accessibility.discussionReportHint
    }
    
    func increaseResponseCount() {
        let count = thread?.responseCount ?? 0
        thread?.responseCount = count + 1
    }
    
    private func showAddedResponse(comment: DiscussionComment) {
        responsesDataController.responses.append(comment)
        tableView.reloadData()
        let indexPath = NSIndexPath(forRow: responsesDataController.responses.count - 1, inSection: TableSection.Responses.rawValue)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
    }
    
    // MARK:- DiscussionNewCommentViewControllerDelegate method
    
    func newCommentController(controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        
        switch controller.currentContext() {
        case .Thread(_):
            if !(paginationController?.hasNext ?? false) {
                showAddedResponse(comment)
            }
            
            increaseResponseCount()
            showOverlayMessage(Strings.discussionThreadPosted)
        case .Comment(_):
            responsesDataController.addedChildComment(comment)
            self.showOverlayMessage(Strings.discussionCommentPosted)
        }
        
        self.tableView.reloadData()
    }
    
    // MARK:- DiscussionCommentsViewControllerDelegate
    
    func discussionCommentsView(controller: DiscussionCommentsViewController, updatedComment comment: DiscussionComment) {
        responsesDataController.updateResponsesWithComment(comment)
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
    var author : String? { get }
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
        
        if let _ = name where OEXConfig.sharedConfig().profilesEnabled {
            highlightStyle.color = OEXStyles.sharedStyles().primaryBaseColor()
            highlightStyle.weight = .SemiBold
        }
        else {
            highlightStyle.color = OEXStyles.sharedStyles().neutralBase()
            highlightStyle.weight = textStyle.weight
        }
            
        let formattedUserName = highlightStyle.attributedStringWithText(name ?? Strings.anonymous.oex_lowercaseStringInCurrentLocale())
        
        let byAuthor =  textStyle.apply(Strings.byAuthorLowerCase) (formattedUserName)
        
        attributedStrings.append(byAuthor)
        
        if let authorLabel = label {
            attributedStrings.append(textStyle.attributedStringWithText(Strings.parenthesis(text: authorLabel)))
        }
        
        return NSAttributedString.joinInNaturalLayout(attributedStrings)
    }
}
