//
//  DiscussionResponsesViewController.swift
//  edX
//
//  Created by Lim, Jake on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let GeneralPadding: CGFloat = 8.0

private let cellButtonStyle = OEXTextStyle(weight:.normal, size:.base, color: OEXStyles.shared().neutralDark())
private let cellIconSelectedStyle = cellButtonStyle.withColor(OEXStyles.shared().primaryBaseColor())
private let responseMessageStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
private let disabledCommentStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBase())

class DiscussionCellButton: UIButton {
    var indexPath: IndexPath?
    
}

class DiscussionPostCell: UITableViewCell {
    static let identifier = "DiscussionPostCell"

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var bodyTextLabel: UILabel!
    @IBOutlet fileprivate var visibilityLabel: UILabel!
    @IBOutlet fileprivate var authorButton: UIButton!
    @IBOutlet fileprivate var responseCountLabel:UILabel!
    @IBOutlet fileprivate var voteButton: DiscussionCellButton!
    @IBOutlet fileprivate var followButton: DiscussionCellButton!
    @IBOutlet fileprivate var reportButton: DiscussionCellButton!
    @IBOutlet fileprivate var separatorLine: UIView!
    @IBOutlet fileprivate var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        for (button, icon, text) in [
            (voteButton!, Icon.UpVote, ""),
            (followButton!, Icon.FollowStar, Strings.discussionFollow),
            (reportButton!, Icon.ReportFlag, Strings.discussionReport)
            ]
           
        {
            let buttonText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon.attributedTextWithStyle(style: cellButtonStyle, inline: true),
                cellButtonStyle.attributedString(withText: text )])
            button.setAttributedTitle(buttonText, for:.normal)
        }
        
        separatorLine.backgroundColor = OEXStyles.shared().standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .Leading
        followButton.localizedHorizontalContentAlignment = .Center
        reportButton.localizedHorizontalContentAlignment = .Trailing
        authorButton.localizedHorizontalContentAlignment = .Leading
        DiscussionHelper.styleAuthorProfileImageView(imageView: authorProfileImage)
    }
    
    func setAccessibility(thread: DiscussionThread) {
        
        var accessibilityString = ""
        let sentenceSeparator = ", "
        
        if let title = thread.title {
            accessibilityString.append(title + sentenceSeparator)
        }
        
        if let body = thread.rawBody {
            accessibilityString.append(body + sentenceSeparator)
        }
        
        if let date = dateLabel.text {
            accessibilityString.append(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.append(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if let visibility = visibilityLabel.text {
            accessibilityString.append(visibility)
        }
        
        if let responseCount = responseCountLabel.text {
            accessibilityString.append(responseCount)
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
    @IBOutlet fileprivate var bodyTextView: UITextView!
    @IBOutlet fileprivate var authorButton: UIButton!
    @IBOutlet fileprivate var voteButton: DiscussionCellButton!
    @IBOutlet fileprivate var reportButton: DiscussionCellButton!
    @IBOutlet fileprivate var commentButton: DiscussionCellButton!
    @IBOutlet fileprivate var commentBox: UIView!
    @IBOutlet fileprivate var endorsedLabel: UILabel!
    @IBOutlet fileprivate var separatorLine: UIView!
    @IBOutlet fileprivate var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var endorsedByButton: UIButton!
    @IBOutlet weak var authorProfileImage: UIImageView!
    @IBOutlet weak var authorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        
        for (button, icon, text) in [
            (reportButton!, Icon.ReportFlag, Strings.discussionReport)]
        {
            let iconString = icon.attributedTextWithStyle(style: cellButtonStyle, inline: true)
            let buttonText = NSAttributedString.joinInNaturalLayout(attributedStrings: [iconString,
                cellButtonStyle.attributedString(withText: text)])
            button.setAttributedTitle(buttonText, for:.normal)
        }
        
        commentBox.backgroundColor = OEXStyles.shared().neutralXXLight()
        
        separatorLine.backgroundColor = OEXStyles.shared().standardDividerColor
        separatorLineHeightConstraint.constant = OEXStyles.dividerSize()

        voteButton.localizedHorizontalContentAlignment = .Leading
        reportButton.localizedHorizontalContentAlignment = .Trailing
        authorButton.localizedHorizontalContentAlignment = .Leading
        endorsedByButton.localizedHorizontalContentAlignment = .Leading

        containerView.applyBorderStyle(style: BorderStyle())
        
        accessibilityTraits = UIAccessibilityTraitHeader
        bodyTextView.isAccessibilityElement = false
        endorsedByButton.isAccessibilityElement = false
    }
    
    var endorsed : Bool = false {
        didSet {
            endorsedLabel.isHidden = !endorsed
            endorsedByButton.isHidden = !endorsed
        }
    }
    
    var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().utilitySuccessBase())
    }
    
    override func updateConstraints() {
        if endorsedByButton.isHidden {
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
        accessibilityString.append(body + sentenceSeparator)
        
        if let date = dateLabel.text {
            accessibilityString.append(Strings.Accessibility.discussionPostedOn(date: date) + sentenceSeparator)
        }
        
        if let author = authorNameLabel.text {
            accessibilityString.append(Strings.accessibilityBy + " " + author + sentenceSeparator)
        }
        
        if endorsedByButton.isHidden == false {
            if let endorsed = endorsedByButton.attributedTitle(for: .normal)?.string  {
                accessibilityString.append(endorsed + sentenceSeparator)
            }
        }
        
        if response.childCount > 0 {
            accessibilityString.append(Strings.commentsToResponse(count: response.childCount))
        }
        
        self.accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}


class DiscussionResponsesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate, DiscussionCommentsViewControllerDelegate, InterfaceOrientationOverriding {
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & OEXConfigProvider & OEXAnalyticsProvider & DataManagerProvider

    enum TableSection : Int {
        case Post = 0
        case EndorsedResponses = 1
        case Responses = 2
    }
    
    var environment: Environment!
    var courseID: String!
    var isDiscussionBlackedOut: Bool = false
    
    var loadController : LoadStateViewController?
    var paginationController : PaginationController<DiscussionComment>?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var contentView: UIView!
    
    private let addResponseButton = UIButton(type: .system)
    private let responsesDataController = DiscussionResponsesDataController()
    var thread: DiscussionThread?
    var postFollowing = false
    var profileFeed: Feed<UserProfile>?
    var tempComment: DiscussionComment? // this will be used for injecting user info to added comment

    func loadContent() {
        loadResponses()
        
        let styles = OEXStyles.shared()
        let footerStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralWhite())
        
        let icon = postClosed ? Icon.Closed : Icon.Create
        let text = postClosed ? Strings.responsesClosed : Strings.addAResponse
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon.attributedTextWithStyle(style: footerStyle.withSize(.xSmall)),
            footerStyle.attributedString(withText: text)])
        
        addResponseButton.setAttributedTitle(buttonTitle, for: .normal)
        
        let postingEnabled = (postClosed || isDiscussionBlackedOut)
        addResponseButton.backgroundColor = postingEnabled ? styles.neutralBase() : styles.primaryXDarkColor()
        addResponseButton.isEnabled = !postingEnabled

        addResponseButton.oex_removeAllActions()
        if !(thread?.closed ?? true){
            addResponseButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
                if let owner = self, let thread = owner.thread {
                    owner.environment.router?.showDiscussionNewCommentFromController(controller: owner, courseID: owner.courseID, thread: thread, context: .Thread(thread))
                }
                }, for: UIControlEvents.touchUpInside)
        }
        
        if let thread = thread {
            self.navigationItem.title = navigationItemTitleForThread(thread: thread)
        }
        
        tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) as IndexSet , with: .fade)
    }
    
    var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralXDark())
    }
    
    var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())

    }
    
    override func viewDidLoad() {
        assert(environment != nil)
        assert(courseID != nil)
        
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.shared().discussionsBackgroundColor
        self.contentView.backgroundColor = OEXStyles.shared().neutralXLight()
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        
        loadController = LoadStateViewController()
        
        addResponseButton.contentVerticalAlignment = .center
        view.addSubview(addResponseButton)
        addResponseButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.shared().standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
            make.top.equalTo(tableView.snp_bottom)
        }
        
        tableView.estimatedRowHeight = 160.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        loadController?.setupInController(controller: self, contentView: contentView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        
        markThreadAsRead()
        setupProfileLoader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func logScreenEvent(){
        if let thread = thread {
            
            self.environment.analytics.trackDiscussionScreen(withName: AnalyticsScreenName.ViewThread, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil, author: thread.author)
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
        let apiRequest = DiscussionAPI.readThread(read: true, threadID: thread?.threadID ?? "")
        self.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            if let thread = result.data {
                self?.patchThread(thread: thread)
                self?.loadContent()
            }
        }
    }
    
    private func refreshTableData() {
        tableView.reloadSections(NSIndexSet(index: TableSection.Post.rawValue) as IndexSet , with: .fade)
    }
    
    private func patchThread(thread: DiscussionThread) {
        var injectedThread = thread
        injectedThread.hasProfileImage = self.thread?.hasProfileImage ?? false
        injectedThread.imageURL = self.thread?.imageURL ?? ""
        self.thread = injectedThread
        refreshTableData()
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
            return DiscussionAPI.getResponses(environment: self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, endorsedOnly: true, pageNumber: page)
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
                self?.loadController?.state = LoadState.failed(error: error)
                
            })
        
        paginationController?.loadMore()
    }
    
    private func loadUnansweredResponses() {
        
        guard let thread = thread else { return }
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getResponses(environment: self.environment.router?.environment, threadID: thread.threadID, threadType: thread.type, pageNumber: page)
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
                if self?.responsesDataController.endorsedResponses.count ?? 0 <= 0 {
                    self?.loadController?.state = LoadState.failed(error: error)
                }
                else {
                    self?.loadController?.state = .Loaded
                }
            })
        
        paginationController?.loadMore()
    }
    
    @IBAction func commentTapped(sender: AnyObject) {
        if let button = sender as? DiscussionCellButton, let indexPath = button.indexPath {
            
            let aResponse:DiscussionComment?
            
            switch TableSection(rawValue: indexPath.section) {
            case .some(.EndorsedResponses):
                aResponse = responsesDataController.endorsedResponses[indexPath.row]
            case .some(.Responses):
                aResponse = responsesDataController.responses[indexPath.row]
            default:
                aResponse = nil
            }
            
            if let response = aResponse {
                if response.childCount == 0{
                    if !postClosed {
                        guard let thread = thread else { return }
                        
                        environment.router?.showDiscussionNewCommentFromController(controller: self, courseID: courseID, thread:thread, context: .Comment(response))
                    }
                } else {
                    guard let thread = thread else { return }
                    
                    environment.router?.showDiscussionCommentsFromViewController(controller: self, courseID : courseID, response: response, closed : postClosed, thread: thread, isDiscussionBlackedOut: isDiscussionBlackedOut)
                }
            }
        }
    }
    
    // Mark - tableview delegate methods

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue: section) {
        case .some(.Post): return 1
        case .some(.EndorsedResponses): return responsesDataController.endorsedResponses.count
        case .some(.Responses): return responsesDataController.responses.count
        case .none:
            assert(false, "Unknown table section")
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        switch TableSection(rawValue: indexPath.section) {
        case .some(.Post):
            cell.backgroundColor = UIColor.white
        case .some(.EndorsedResponses):
            cell.backgroundColor = UIColor.clear
        case .some(.Responses):
            cell.backgroundColor = UIColor.clear
        default:
            assert(false, "Unknown table section")
        }
    }
    
    func applyThreadToCell(cell: DiscussionPostCell) -> UITableViewCell {
        if let thread = self.thread {
            cell.titleLabel.attributedText = titleTextStyle.attributedString(withText: thread.title)
            
            cell.bodyTextLabel.attributedText = detailTextStyle.attributedString(withText: thread.rawBody)
            
            let visibilityString : String
            if let cohortName = thread.groupName {
                visibilityString = Strings.postVisibility(cohort: cohortName)
            }
            else {
                visibilityString = Strings.postVisibilityEveryone
            }
            cell.visibilityLabel.attributedText = infoTextStyle.attributedString(withText: visibilityString)
            
            DiscussionHelper.styleAuthorDetails(author: thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)

            if let responseCount = thread.responseCount {
                let icon = Icon.Comment.attributedTextWithStyle(style: infoTextStyle)
                let countLabelText = infoTextStyle.attributedString(withText: Strings.response(count: responseCount))
                
                let labelText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon,countLabelText])
                cell.responseCountLabel.attributedText = labelText
            }
            else {
                cell.responseCountLabel.attributedText = nil
            }
            
            updateVoteText(button: cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
            updateFollowText(button: cell.followButton, following: thread.following)
        }
        
        // vote a post (thread) - User can only vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, let button = action as? DiscussionCellButton, let thread = owner.thread {
                button.isEnabled = false
                
                let apiRequest = DiscussionAPI.voteThread(voted: thread.voted, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                    button.isEnabled = true
                    
                    if let thread: DiscussionThread = result.data {
                        self?.patchThread(thread: thread)
                        owner.updateVoteText(button: cell.voteButton, voteCount: thread.voteCount, voted: thread.voted)
                    }
                    else {
                        self?.showOverlay(withMessage: DiscussionHelper.messageForError(error: result.error))
                    }
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        // follow a post (thread) - User can only follow original post, not response or comment.
        cell.followButton.oex_removeAllActions()
        cell.followButton.oex_addAction({[weak self] (sender : AnyObject!) -> Void in
            if let owner = self, let thread = owner.thread {
                let apiRequest = DiscussionAPI.followThread(following: owner.postFollowing, threadID: thread.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread: DiscussionThread = result.data {
                        owner.updateFollowText(button: cell.followButton, following: thread.following)
                        owner.postFollowing = thread.following
                    }
                    else {
                        self?.showOverlay(withMessage: DiscussionHelper.messageForError(error: result.error))
                    }
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        if let item = self.thread {
            updateVoteText(button: cell.voteButton, voteCount: item.voteCount, voted: item.voted)
            updateFollowText(button: cell.followButton, following: item.following)
            updateReportText(button: cell.reportButton, report: thread!.abuseFlagged)
        }
        
        // report (flag) a post (thread) - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            if let owner = self, let item = owner.thread {
                let apiRequest = DiscussionAPI.flagThread(abuseFlagged: !item.abuseFlagged, threadID: item.threadID)
                
                owner.environment.networkManager.taskForRequest(apiRequest) { result in
                    if let thread = result.data {
                        self?.thread?.abuseFlagged = thread.abuseFlagged
                        owner.updateReportText(button: cell.reportButton, report: thread.abuseFlagged)
                    }
                    else {
                        self?.showOverlay(withMessage: DiscussionHelper.messageForError(error: result.error))
                    }
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        if let thread = self.thread {
            cell.setAccessibility(thread: thread)
        }
        
        
        return cell

    }
    
    func cellForResponseAtIndexPath(indexPath : IndexPath, response: DiscussionComment) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionResponseCell.identifier, for: indexPath) as! DiscussionResponseCell
        
        cell.bodyTextView.attributedText = detailTextStyle.markdownString(withText: response.renderedBody)
        
        if let thread = thread {
            let formatedTitle = response.formattedUserLabel(name: response.endorsedBy, date: response.endorsedAt,label: response.endorsedByLabel ,endorsedLabel: true, threadType: thread.type, textStyle: infoTextStyle)
            
            cell.endorsedByButton.setAttributedTitle(formatedTitle, for: .normal)
            
            cell.endorsedByButton.snp_updateConstraints(closure: { (make) in
                make.width.equalTo(formatedTitle.singleLineWidth() + StandardHorizontalMargin)
            })
        }
        
        DiscussionHelper.styleAuthorDetails(author: response.author, authorLabel: response.authorLabel, createdAt: response.createdAt, hasProfileImage: response.hasProfileImage, imageURL: response.imageURL, authoNameLabel: cell.authorNameLabel, dateLabel: cell.dateLabel, authorButton: cell.authorButton, imageView: cell.authorProfileImage, viewController: self, router: environment.router)
        
        DiscussionHelper.styleAuthorProfileImageView(imageView: cell.authorProfileImage)
        
        let profilesEnabled = self.environment.config.profilesEnabled
        
        if profilesEnabled && response.endorsed {
            cell.endorsedByButton.oex_removeAllActions()
            cell.endorsedByButton.oex_addAction({ [weak self] _ in
                
                guard let endorsedBy = response.endorsedBy else { return }
                
                self?.environment.router?.showProfileForUsername(controller: self, username: endorsedBy, editable: false)
                }, for: .touchUpInside)
        }

        let prompt : String
        let icon : Icon
        let commentStyle : OEXTextStyle
        
        if response.childCount == 0 {
            prompt = postClosed ? Strings.commentsClosed : Strings.addAComment
            icon = postClosed ? Icon.Closed : Icon.Comment
            commentStyle = isDiscussionBlackedOut ? disabledCommentStyle : responseMessageStyle
            cell.commentButton.isEnabled = !isDiscussionBlackedOut
        }
        else {
            prompt = Strings.commentsToResponse(count: response.childCount)
            icon = Icon.Comment
            commentStyle = responseMessageStyle
        }
       
        let iconText = icon.attributedTextWithStyle(style: commentStyle, inline : true)
        let styledPrompt = commentStyle.attributedString(withText: prompt)
        let title = NSAttributedString.joinInNaturalLayout(attributedStrings: [iconText,styledPrompt])

        UIView.performWithoutAnimation {
            cell.commentButton.setAttributedTitle(title, for: .normal)
        }
        
        let voteCount = response.voteCount
        let voted = response.voted
        cell.commentButton.indexPath = indexPath

        updateVoteText(button: cell.voteButton, voteCount: voteCount, voted: voted)
        updateReportText(button: cell.reportButton, report: response.abuseFlagged)
        
        cell.voteButton.indexPath = indexPath
        // vote/unvote a response - User can vote on post and response not on comment.
        cell.voteButton.oex_removeAllActions()
        cell.voteButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            
            let apiRequest = DiscussionAPI.voteResponse(voted: response.voted, responseID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment: DiscussionComment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment: comment)
                    self?.updateVoteText(button: cell.voteButton, voteCount: comment.voteCount, voted: comment.voted)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlay(withMessage: DiscussionHelper.messageForError(error: result.error))
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        cell.reportButton.indexPath = indexPath
        // report (flag)/unflag a response - User can report on post, response, or comment.
        cell.reportButton.oex_removeAllActions()
        cell.reportButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
            let apiRequest = DiscussionAPI.flagComment(abuseFlagged: !response.abuseFlagged, commentID: response.commentID)
            
            self?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let comment = result.data {
                    self?.responsesDataController.updateResponsesWithComment(comment: comment)
                    
                    self?.updateReportText(button: cell.reportButton, report: comment.abuseFlagged)
                    self?.tableView.reloadData()
                }
                else {
                    self?.showOverlay(withMessage: DiscussionHelper.messageForError(error: result.error))
                }
            }
            }, for: UIControlEvents.touchUpInside)
        
        cell.endorsed = response.endorsed
        
        if let thread = thread {
            DiscussionHelper.updateEndorsedTitle(thread: thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            cell.setAccessibility(response: response)
        }
        
        return cell
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch TableSection(rawValue: indexPath.section) {
        case .some(.Post):
            let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionPostCell.identifier, for: indexPath as IndexPath) as! DiscussionPostCell
            return applyThreadToCell(cell: cell)
        case .some(.EndorsedResponses):
            return cellForResponseAtIndexPath(indexPath: indexPath, response: responsesDataController.endorsedResponses[indexPath.row])
        case .some(.Responses):
            return cellForResponseAtIndexPath(indexPath: indexPath, response: responsesDataController.responses[indexPath.row])
        case .none:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }

    private func updateVoteText(button: DiscussionCellButton, voteCount: Int, voted: Bool) {
        // TODO: show upvote and downvote depending on voted?
        let iconStyle = voted ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout(attributedStrings: [
            Icon.UpVote.attributedTextWithStyle(style: iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: Strings.vote(count: voteCount))])
        button.setAttributedTitle(buttonText, for:.normal)
        button.accessibilityHint = voted ? Strings.Accessibility.discussionUnvoteHint : Strings.Accessibility.discussionVoteHint
    }
    
    private func updateFollowText(button: DiscussionCellButton, following: Bool) {
        let iconStyle = following ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout(attributedStrings: [Icon.FollowStar.attributedTextWithStyle(style: iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: following ? Strings.discussionUnfollow : Strings.discussionFollow )])
        button.setAttributedTitle(buttonText, for:.normal)
        button.accessibilityHint = following ? Strings.Accessibility.discussionUnfollowHint : Strings.Accessibility.discussionFollowHint
    }
    
    private func updateReportText(button: DiscussionCellButton, report: Bool) {
        let iconStyle = report ? cellIconSelectedStyle : cellButtonStyle
        let buttonText = NSAttributedString.joinInNaturalLayout(attributedStrings: [Icon.ReportFlag.attributedTextWithStyle(style: iconStyle, inline : true),
            cellButtonStyle.attributedString(withText: report ? Strings.discussionUnreport : Strings.discussionReport )])
        button.setAttributedTitle(buttonText, for:.normal)
        button.accessibilityHint = report ? Strings.Accessibility.discussionUnreportHint : Strings.Accessibility.discussionReportHint
    }
    
    func increaseResponseCount() {
        let count = thread?.responseCount ?? 0
        thread?.responseCount = count + 1
    }
    
    private func showAddedResponse(comment: DiscussionComment) {
        responsesDataController.responses.append(comment)
        tableView.reloadData()
        let indexPath = IndexPath(row: responsesDataController.responses.count - 1, section: TableSection.Responses.rawValue)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = self.environment.dataManager.userProfileManager.feedForCurrentUser()
        profileFeed?.output.listen(self,  success: { [weak self] profile in
            if var comment = self?.tempComment {
                comment.hasProfileImage = !((profile.imageURL?.isEmpty) ?? true )
                comment.imageURL = profile.imageURL ?? ""
                self?.showAddedResponse(comment: comment)
                self?.tempComment = nil
            }
        }, failure : { _ in
            Logger.logError("Profiles", "Unable to fetch profile")
        })
    }
    
    // MARK:- DiscussionNewCommentViewControllerDelegate method
    
    func newCommentController(controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        
        switch controller.currentContext() {
        case .Thread(_):
            if !(paginationController?.hasNext ?? false) {
                self.tempComment = comment
                profileFeed?.refresh()
            }
            
            increaseResponseCount()
            showOverlay(withMessage: Strings.discussionThreadPosted)
        case .Comment(_):
            responsesDataController.addedChildComment(comment: comment)
            self.showOverlay(withMessage:Strings.discussionCommentPosted)
        }
        
        self.tableView.reloadData()
    }
    
    // MARK:- DiscussionCommentsViewControllerDelegate
    
    func discussionCommentsView(controller: DiscussionCommentsViewController, updatedComment comment: DiscussionComment) {
        responsesDataController.updateResponsesWithComment(comment: comment)
        self.tableView.reloadData()
    }
}

extension NSDate {
    
    private var shouldDisplayTimeSpan : Bool {
        let currentDate = NSDate()
        return currentDate.days(from: self as Date!) < 7
    }
    
    public var displayDate : String {
        return shouldDisplayTimeSpan ? self.timeAgoSinceNow() : DateFormatting.format(asDateMonthYearString: self)
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
        return formattedUserLabel(name: author, date: createdAt, label: authorLabel, threadType: nil, textStyle: textStyle)
    }
    
    func formattedUserLabel(name: String?, date: NSDate?, label: String?, endorsedLabel:Bool = false, threadType:DiscussionThreadType?, textStyle : OEXTextStyle) -> NSAttributedString {
        var attributedStrings = [NSAttributedString]()
        
        if let threadType = threadType {
            switch threadType {
            case .Question where endorsedLabel:
                attributedStrings.append(textStyle.attributedString(withText: Strings.markedAnswer))
            case .Discussion where endorsedLabel:
                attributedStrings.append(textStyle.attributedString(withText: Strings.endorsed))
            default: break
            }
        }
        
        if let displayDate = date {
            attributedStrings.append(textStyle.attributedString(withText: displayDate.displayDate))
        }
        
        let highlightStyle = OEXMutableTextStyle(textStyle: textStyle)
        
        if let _ = name, OEXConfig.shared().profilesEnabled {
            highlightStyle.color = OEXStyles.shared().primaryBaseColor()
            highlightStyle.weight = .semiBold
        }
        else {
            highlightStyle.color = OEXStyles.shared().neutralBase()
            highlightStyle.weight = textStyle.weight
        }
            
        let formattedUserName = highlightStyle.attributedString(withText: name ?? Strings.anonymous.oex_lowercaseStringInCurrentLocale())
        
        let byAuthor =  textStyle.attributedString(withText: Strings.byAuthorLowerCase(authorName: formattedUserName.string))
        
        attributedStrings.append(byAuthor)
        
        if let authorLabel = label {
            attributedStrings.append(textStyle.attributedString(withText: Strings.parenthesis(text: authorLabel)))
        }
        
        return NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
    }
}
