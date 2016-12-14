//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var commentTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralDark())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralDark())
}

private var smallIconStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
}

private let smallIconSelectedStyle = smallIconStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())

private let UserProfileImageSize = CGSizeMake(40.0,40.0)

class DiscussionCommentCell: UITableViewCell {
    
    private let bodyTextView = UITextView()
    private let authorButton = UIButton(type: .System)
    private let commentCountOrReportIconButton = UIButton(type: .System)
    private let divider = UIView()
    private let containerView = UIView()
    private let endorsedLabel = UILabel()
    private let authorProfileImage = UIImageView()
    private let authorNameLabel = UILabel()
    private let dateLabel = UILabel()
    
    private var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    private func setEndorsed(endorsed : Bool) {
        endorsedLabel.hidden = !endorsed
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None
        
        applyStandardSeparatorInsets()
        addSubViews()
        setConstraints()
        bodyTextView.editable = false
        bodyTextView.dataDetectorTypes = UIDataDetectorTypes.All
        bodyTextView.scrollEnabled = false
        bodyTextView.backgroundColor = UIColor.clearColor()
        containerView.userInteractionEnabled = true
        commentCountOrReportIconButton.localizedHorizontalContentAlignment = .Trailing
        contentView.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        divider.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        containerView.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        containerView.applyBorderStyle(BorderStyle())
        accessibilityTraits = UIAccessibilityTraitHeader
        bodyTextView.isAccessibilityElement = false
    }
    
    private func addSubViews() {
       contentView.addSubview(containerView)
        containerView.addSubview(bodyTextView)
        containerView.addSubview(authorButton)
        containerView.addSubview(endorsedLabel)
        containerView.addSubview(commentCountOrReportIconButton)
        containerView.addSubview(divider)
        containerView.addSubview(authorProfileImage)
        containerView.addSubview(authorNameLabel)
        containerView.addSubview(dateLabel)
    }
    
    private func setConstraints() {
        
        containerView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(0, StandardHorizontalMargin, 0, StandardHorizontalMargin))
        }
        
        authorProfileImage.snp_makeConstraints { (make) in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.width.equalTo(UserProfileImageSize.width)
            make.height.equalTo(UserProfileImageSize.height)
        }
        
        authorNameLabel.snp_makeConstraints { (make) in
            make.top.equalTo(authorProfileImage)
            make.leading.equalTo(authorProfileImage.snp_trailing).offset(StandardHorizontalMargin)
        }
        
        dateLabel.snp_makeConstraints { (make) in
            make.top.equalTo(authorNameLabel.snp_bottom)
            make.leading.equalTo(authorNameLabel)
        }
        
        authorButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(authorProfileImage)
            make.leading.equalTo(contentView)
            make.bottom.equalTo(authorProfileImage)
            make.trailing.equalTo(dateLabel)
            make.trailing.equalTo(authorNameLabel)
        }
        
        endorsedLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(dateLabel)
            make.top.equalTo(dateLabel.snp_bottom)
        }
        
        bodyTextView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(authorProfileImage.snp_bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(authorProfileImage)
            make.trailing.equalTo(containerView).offset(-StandardHorizontalMargin)
        }
        
        commentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(containerView).offset(-OEXStyles.sharedStyles().standardHorizontalMargin())
            make.top.equalTo(authorNameLabel)
        }
        
        divider.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextView.snp_bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.height.equalTo(StandardVerticalMargin)
            make.bottom.equalTo(containerView)
        }
    }
    
    func useResponse(response : DiscussionComment, viewController : DiscussionCommentsViewController) {
        divider.snp_updateConstraints { (make) in
            make.height.equalTo(StandardVerticalMargin)
        }
        bodyTextView.attributedText = commentTextStyle.markdownStringWithText(response.renderedBody)
        DiscussionHelper.styleAuthorDetails(response.author, authorLabel: response.authorLabel, createdAt: response.createdAt, hasProfileImage: response.hasProfileImage, imageURL: response.imageURL, authoNameLabel: authorNameLabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: viewController, router: viewController.environment.router)
        
        let message = Strings.comment(count: response.childCount)
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.Comment.attributedTextWithStyle(smallIconStyle),
            smallTextStyle.attributedStringWithText(message)])
        commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        setEndorsed(response.endorsed)
        setNeedsLayout()
        layoutIfNeeded()
        
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
        
        setAccessiblity(commentCountOrReportIconButton.currentAttributedTitle?.string)
    }
    
    func useComment(comment : DiscussionComment, inViewController viewController : DiscussionCommentsViewController, index: NSInteger) {
        divider.snp_updateConstraints { (make) in
            make.height.equalTo(2)
        }
        bodyTextView.attributedText = commentTextStyle.markdownStringWithText(comment.renderedBody)
        updateReportText(commentCountOrReportIconButton, report: comment.abuseFlagged)
        DiscussionHelper.styleAuthorDetails(comment.author, authorLabel: comment.authorLabel, createdAt: comment.createdAt, hasProfileImage: comment.hasProfileImage, imageURL: comment.imageURL, authoNameLabel: authorNameLabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: viewController, router: viewController.environment.router)
        
        commentCountOrReportIconButton.oex_removeAllActions()
        commentCountOrReportIconButton.oex_addAction({[weak viewController] _ -> Void in
            
            let apiRequest = DiscussionAPI.flagComment(!comment.abuseFlagged, commentID: comment.commentID)
            viewController?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let response = result.data {
                    if viewController?.comments.count > index && viewController?.comments[index].commentID == response.commentID {
                        viewController?.comments[index] = response
                        self.updateReportText(self.commentCountOrReportIconButton, report: response.abuseFlagged)
                        viewController?.tableView.reloadData()
                    }
                }
                else {
                    viewController?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        
        setEndorsed(false)
        setNeedsLayout()
        layoutIfNeeded()
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
        
        setAccessiblity(nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateReportText(button: UIButton, report: Bool) {
        
        let iconStyle = report ? smallIconSelectedStyle : smallIconStyle
        let reportIcon = Icon.ReportFlag.attributedTextWithStyle(iconStyle)
        let reportTitle = smallTextStyle.attributedStringWithText((report ? Strings.discussionUnreport : Strings.discussionReport ))
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([reportIcon, reportTitle])
        button.setAttributedTitle(buttonTitle, forState: .Normal)
        
        button.snp_remakeConstraints { (make) in
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
            make.width.equalTo(buttonTitle.singleLineWidth() + StandardHorizontalMargin)
            make.trailing.equalTo(contentView).offset(-2*StandardHorizontalMargin)
        }
        
        button.accessibilityHint = report ? Strings.Accessibility.discussionUnreportHint : Strings.Accessibility.discussionReportHint
    }
    
    func setAccessiblity(commentCount : String?) {
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
        
        if let endorsed = endorsedLabel.text where !endorsedLabel.hidden {
            accessibilityString.appendContentsOf(endorsed + sentenceSeparator)
        }
        
        if let comments = commentCount {
            accessibilityString.appendContentsOf(comments)
            commentCountOrReportIconButton.isAccessibilityElement = false
        }
        
        accessibilityLabel = accessibilityString
        
        if let authorName = authorNameLabel.text {
            self.authorButton.accessibilityLabel = authorName
            self.authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
    }
}

protocol DiscussionCommentsViewControllerDelegate: class {
    
    func discussionCommentsView(controller  : DiscussionCommentsViewController, updatedComment comment: DiscussionComment)
}

class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DiscussionNewCommentViewControllerDelegate, InterfaceOrientationOverriding {
    
    typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider>
    
    private enum TableSection : Int {
        case Response = 0
        case Comments = 1
    }
    
    private let identifierCommentCell = "CommentCell"
    private let environment: Environment
    private let courseID: String
    private let discussionManager : DiscussionDataManager
    private var loadController : LoadStateViewController
    private let contentView = UIView()
    private let addCommentButton = UIButton(type: .System)
    private var tableView: UITableView!
    private var comments : [DiscussionComment]  = []
    private var responseItem: DiscussionComment
    weak var delegate: DiscussionCommentsViewControllerDelegate?
    
    //Since didSet doesn't get called from within initialization context, we need to set it with another variable.
    private var commentsClosed : Bool = false {
        didSet {
            let styles = OEXStyles.sharedStyles()
            
            addCommentButton.backgroundColor = commentsClosed ? styles.neutralBase() : styles.primaryXDarkColor()
            
            let textStyle = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralWhite())
            let icon = commentsClosed ? Icon.Closed : Icon.Create
            let buttonText = commentsClosed ? Strings.commentsClosed : Strings.addAComment
            let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(textStyle.withSize(.XSmall)), textStyle.attributedStringWithText(buttonText)])
            
            addCommentButton.setAttributedTitle(buttonTitle, forState: .Normal)
            addCommentButton.enabled = !commentsClosed
            
            if (!commentsClosed) {
                addCommentButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                    if let owner = self {
                        
                        guard let thread = owner.thread else { return }
                        
                        owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, thread: thread, context: .Comment(owner.responseItem))
                    }
                    }, forEvents: UIControlEvents.TouchUpInside)
            }
        }
    }
    
    private var commentID: String {
        return responseItem.commentID
    }
    
    var paginationController : PaginationController<DiscussionComment>?
    
    //Only used to set commentsClosed out of initialization context
    //TODO: Get rid of this variable when Swift improves
    private var closed : Bool = false
    private let thread: DiscussionThread?
    
    init(environment: Environment, courseID : String, responseItem: DiscussionComment, closed : Bool, thread: DiscussionThread?) {
        self.courseID = courseID
        self.environment = environment
        self.responseItem = responseItem
        self.thread = thread
        self.discussionManager = self.environment.dataManager.courseDataManager.discussionManagerForCourseWithID(self.courseID)
        self.closed = closed
        self.loadController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: view.bounds, style: .Plain)
        tableView.registerClass(DiscussionCommentCell.classForCoder(), forCellReuseIdentifier: identifierCommentCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        addSubviews()
        setStyles()
        setConstraints()
        
        loadController.setupInController(self, contentView: self.contentView)
        
        self.commentsClosed = self.closed
        
        initializePaginator()
        loadContent()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    private func logScreenEvent() {
        self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenViewResponseComments, courseId: self.courseID, value: thread?.title, threadId: responseItem.threadID, topicId: nil, responseID: responseItem.commentID)
    }
    
    func addSubviews() {
        view.addSubview(contentView)
        contentView.addSubview(tableView)
        view.addSubview(addCommentButton)
    }
    
    func setStyles() {
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.applyStandardSeparatorInsets()
        tableView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        tableView.contentInset = UIEdgeInsetsMake(10.0, 0, 0, 0)
        tableView.clipsToBounds = true
        
        self.navigationItem.title = Strings.comments
        view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        addCommentButton.contentVerticalAlignment = .Center
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    func setConstraints() {
        contentView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view.snp_leading)
            make.top.equalTo(view)
            make.trailing.equalTo(view.snp_trailing)
            make.bottom.equalTo(addCommentButton.snp_top)
        }
        
        addCommentButton.snp_makeConstraints{ (make) -> Void in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(OEXStyles.sharedStyles().standardFooterHeight)
            make.bottom.equalTo(view.snp_bottom)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(view.snp_leading)
            make.top.equalTo(view)
            make.trailing.equalTo(view.snp_trailing)
            make.bottom.equalTo(addCommentButton.snp_top)
        }
        
        
    }
    
    private func initializePaginator() {
        
        let commentID = self.commentID
        precondition(!commentID.isEmpty, "Shouldn't be showing comments for empty commentID")
        
        let paginator = WrappedPaginator(networkManager: self.environment.networkManager) { page in
            return DiscussionAPI.getComments(self.environment.router?.environment, commentID: commentID, pageNumber: page)
        }
        paginationController = PaginationController(paginator: paginator, tableView: self.tableView)
    }
    
    private func loadContent() {
        paginationController?.stream.listen(self, success:
            { [weak self] comments in
                self?.loadController.state = .Loaded
                self?.comments = comments
                self?.tableView.reloadData()
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
            }, failure: { [weak self] (error) -> Void in
                self?.loadController.state = LoadState.failed(error)
        })
        
        paginationController?.loadMore()
    }
    
    private func showAddedComment(comment: DiscussionComment) {
        comments.append(comment)
        tableView.reloadData()
        let indexPath = NSIndexPath(forRow: comments.count - 1, inSection: TableSection.Comments.rawValue)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
    }
    
    // MARK - tableview delegate methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch TableSection(rawValue:section) {
        case .Some(.Response): return 1
        case .Some(.Comments): return comments.count
        case .None:
            assert(true, "Unexepcted table section")
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifierCommentCell, forIndexPath: indexPath) as! DiscussionCommentCell
        
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Response):
            cell.useResponse(responseItem, viewController: self)
            if let thread = thread {
                DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            }
            
            return cell
        case .Some(.Comments):
            cell.useComment(comments[indexPath.row], inViewController: self, index: indexPath.row)
            return cell
        case .None:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }
    
    // MARK- DiscussionNewCommentViewControllerDelegate method 
    
    func newCommentController(controller: DiscussionNewCommentViewController, addedComment comment: DiscussionComment) {
        responseItem.childCount += 1
        
        if !(paginationController?.hasNext ?? false) {
            showAddedComment(comment)
        }
        
        delegate?.discussionCommentsView(self, updatedComment: responseItem)
        showOverlayMessage(Strings.discussionCommentPosted)
    }
}

// Testing only
extension DiscussionCommentsViewController {
    var t_loaded : Stream<()> {
        return self.paginationController!.stream.map {_ in
            return
        }
    }
}
