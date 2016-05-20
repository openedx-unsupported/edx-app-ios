//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var commentTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralDark())
}

private var mediaTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXSmall, color : OEXStyles.sharedStyles().neutralBase())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXSmall, color : OEXStyles.sharedStyles().neutralBase())
}

private var smallIconStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralDark())
}

private let smallIconSelectedStyle = smallIconStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())

class DiscussionCommentCell: UITableViewCell {
    
    private let bodyTextLabel = UILabel()
    private let authorButton = UIButton(type: .System)
    private let commentCountOrReportIconButton = UIButton(type: .System)
    private let divider = UIView()
    private let containerView = IrregularBorderView()
    private let endorsedLabel = UILabel()
    
    private var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    private func setEndorsed(endorsed : Bool, position: CellPosition) {
        
        self.containerView.style = IrregularBorderStyle(position: position, base: BorderStyle())
        let showsDivider = !endorsed && !position.contains(.Bottom)
        self.divider.backgroundColor = showsDivider ? OEXStyles.sharedStyles().neutralXLight() : nil
        
        endorsedLabel.hidden = !endorsed
        //Had to force this in here, because of a compiler bug - (not passing the correct value for endorsed updateConstraints())
        bodyTextLabel.snp_updateConstraints { (make) -> Void in
            if endorsed {
                make.top.equalTo(endorsedLabel.snp_bottom)
            }
            else {
                make.top.equalTo(containerView).offset(StandardVerticalMargin)
            }
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None
        
        applyStandardSeparatorInsets()
        addSubViews()
        setConstraints()
        
        bodyTextLabel.numberOfLines = 0
        containerView.userInteractionEnabled = true
        authorButton.localizedHorizontalContentAlignment = .Leading
        commentCountOrReportIconButton.localizedHorizontalContentAlignment = .Trailing
        contentView.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
    }
    
    private func addSubViews() {
       contentView.addSubview(containerView)
        containerView.addSubview(bodyTextLabel)
        containerView.addSubview(authorButton)
        containerView.addSubview(endorsedLabel)
        containerView.addSubview(commentCountOrReportIconButton)
        containerView.addSubview(divider)
    }
    
    private func setConstraints() {
        
        containerView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(0, StandardHorizontalMargin, 0, StandardHorizontalMargin))
        }
        
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(containerView).offset(-StandardHorizontalMargin)
        }
        
        authorButton.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom)
            make.leading.equalTo(bodyTextLabel)
            make.bottom.equalTo(containerView).offset(-StandardVerticalMargin)
            make.trailing.lessThanOrEqualTo(containerView)
        }
        
        endorsedLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bodyTextLabel)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
        }
        
        commentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(containerView).offset(-OEXStyles.sharedStyles().standardHorizontalMargin())
            make.centerY.equalTo(authorButton)
        }
        
        divider.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.containerView)
            make.trailing.equalTo(self.containerView)
            make.bottom.equalTo(self.containerView)
            make.height.equalTo(OEXStyles.dividerSize())
        }
    }
    
    func useResponse(response : DiscussionComment, position : CellPosition, viewController : DiscussionCommentsViewController) {
        self.containerView.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        self.bodyTextLabel.attributedText = commentTextStyle.attributedStringWithText(response.rawBody)
        
        DiscussionHelper.styleAuthorButton(authorButton, title: response.formattedUserLabel(smallTextStyle), author: response.author, viewController: viewController, router: viewController.environment.router)
        
        let message = Strings.comment(count: response.childCount)
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.Comment.attributedTextWithStyle(smallIconStyle),
            smallTextStyle.attributedStringWithText(message)])
        self.commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal)
        
        self.setEndorsed(response.endorsed, position: position)
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    func useComment(comment : DiscussionComment, inViewController viewController : DiscussionCommentsViewController, position : CellPosition, index: NSInteger) {
        
        bodyTextLabel.attributedText = commentTextStyle.attributedStringWithText(comment.rawBody)
        self.containerView.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
        viewController.updateReportText(commentCountOrReportIconButton, report: comment.abuseFlagged)
        
        DiscussionHelper.styleAuthorButton(authorButton, title: comment.formattedUserLabel(smallTextStyle), author: comment.author, viewController: viewController, router: viewController.environment.router)
        
        commentCountOrReportIconButton.oex_removeAllActions()
        commentCountOrReportIconButton.oex_addAction({[weak viewController] _ -> Void in
            
            let apiRequest = DiscussionAPI.flagComment(!comment.abuseFlagged, commentID: comment.commentID)
            viewController?.environment.networkManager.taskForRequest(apiRequest) { result in
                if let response = result.data {
                    if viewController?.comments.count > index && viewController?.comments[index].commentID == response.commentID {
                        viewController?.comments[index] = response
                        viewController?.updateReportText(self.commentCountOrReportIconButton, report: response.abuseFlagged)
                        viewController?.tableView.reloadData()
                    }
                }
                else {
                    viewController?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        
        
        setEndorsed(false, position: position)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    private let minBodyTextHeight: CGFloat = 20.0
    private let nonBodyTextHeight: CGFloat = 35.0
    private let defaultResponseCellHeight: CGFloat = 50.0
    private let defaultCommentCellHeight: CGFloat = 55.0
    
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
            return DiscussionAPI.getComments(commentID, pageNumber: page)
        }
        paginationController = PaginationController(paginator: paginator, tableView: self.tableView)
    }
    
    private func loadContent() {
        paginationController?.stream.listen(self, success:
            { [weak self] comments in
                self?.loadController.state = .Loaded
                self?.comments = comments
                self?.tableView.reloadData()
            }, failure: { [weak self] (error) -> Void in
                self?.loadController.state = LoadState.failed(error)
        })
        
        paginationController?.loadMore()
    }
    
    private func updateReportText(button: UIButton, report: Bool) {
        
        let iconStyle = report ? smallIconSelectedStyle : smallIconStyle
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.ReportFlag.attributedTextWithStyle(iconStyle),
            smallTextStyle.attributedStringWithText((report ? Strings.discussionUnreport : Strings.discussionReport ))])
        button.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
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
            let hasComments = comments.count > 0
            let position : CellPosition = hasComments ? [.Top] : [.Top, .Bottom]
            cell.useResponse(responseItem, position: position, viewController: self)
            
            if let thread = thread {
                DiscussionHelper.updateEndorsedTitle(thread, label: cell.endorsedLabel, textStyle: cell.endorsedTextStyle)
            }
            
            return cell
        case .Some(.Comments):
            let isLastRow = tableView.isLastRow(indexPath: indexPath)
            let commentPosition = isLastRow ? CellPosition.Bottom : []
            cell.useComment(comments[indexPath.row], inViewController: self, position: commentPosition, index: indexPath.row)
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
            self.comments.append(comment)
        }
        
        self.tableView.reloadData()
        delegate?.discussionCommentsView(self, updatedComment: responseItem)
        
        self.showOverlayMessage(Strings.discussionCommentPosted)
    }
}
