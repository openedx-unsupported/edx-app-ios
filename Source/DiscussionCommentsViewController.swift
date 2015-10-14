//
//  DiscussionCommentsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private var commentTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XSmall, color : OEXStyles.sharedStyles().neutralDark())
}

private var mediaTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXXSmall, color : OEXStyles.sharedStyles().neutralBase())
}

private var smallTextStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXXSmall, color : OEXStyles.sharedStyles().neutralBase())
}

private var smallIconStyle : OEXTextStyle {
    return OEXTextStyle(weight: .Normal, size: .XXXSmall, color: OEXStyles.sharedStyles().neutralDark())
}

class DiscussionCommentCell: UITableViewCell {

    private let bodyTextLabel = UILabel()
    private let authorLabel = UILabel()
    private let commentCountOrReportIconButton = UIButton(type: .System)
    private let divider = UIView()
    private let containerView = UIView()
    private let endorsedLabel = UILabel()
    
    private var endorsedTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    
    private var endorsed : Bool = false {
        didSet {
            let endorsedBorderStyle = BorderStyle( width: .Hairline, color: OEXStyles.sharedStyles().utilitySuccessBase())
            let unendorsedBorderStyle = BorderStyle()
            let borderStyle = endorsed ?  endorsedBorderStyle : unendorsedBorderStyle
            containerView.applyBorderStyle(borderStyle)
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
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .None
        
        applyStandardSeparatorInsets()
        
        bodyTextLabel.numberOfLines = 0
        contentView.addSubview(containerView)
        containerView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(contentView).inset(UIEdgeInsetsMake(0, StandardHorizontalMargin, 0, StandardHorizontalMargin))
        }
        
        containerView.addSubview(bodyTextLabel)
        bodyTextLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(containerView).offset(-StandardHorizontalMargin)
        }
        
        containerView.addSubview(authorLabel)
        authorLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bodyTextLabel.snp_bottom)
            make.leading.equalTo(bodyTextLabel)
            make.bottom.equalTo(containerView).offset(-StandardVerticalMargin)
        }
        
        containerView.addSubview(endorsedLabel)
        endorsedLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(bodyTextLabel)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.bottom.equalTo(bodyTextLabel)
        }
    
        containerView.addSubview(commentCountOrReportIconButton)
        commentCountOrReportIconButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(containerView).offset(-StandardVerticalMargin)
            make.centerY.equalTo(authorLabel)
        }
        
        self.divider.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        
        self.containerView.addSubview(divider)
        
        self.divider.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.containerView)
            make.trailing.equalTo(self.containerView)
            make.bottom.equalTo(self.containerView)
            make.height.equalTo(OEXStyles.dividerSize())
        }
        
        let endorsedIcon = Icon.Answered.attributedTextWithStyle(endorsedTextStyle, inline : true)
        let endorsedText = endorsedTextStyle.attributedStringWithText(Strings.answer)
        
        endorsedLabel.attributedText = NSAttributedString.joinInNaturalLayout([endorsedIcon,endorsedText])
        self.contentView.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
    }
    
    func useResponse(response : DiscussionResponseItem) {
        self.bodyTextLabel.attributedText = commentTextStyle.attributedStringWithText(response.body)
        self.authorLabel.attributedText = response.authorLabelForTextStyle(smallTextStyle)
        
        self.containerView.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        
        let message = Strings.comment(count: Float(response.commentCount))
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.Comment.attributedTextWithStyle(smallIconStyle),
            smallTextStyle.attributedStringWithText(message)])
        self.commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        self.endorsed = response.endorsed
    }
    
    func useComment(comment : DiscussionComment, inViewController viewController : DiscussionCommentsViewController) {
        bodyTextLabel.attributedText = commentTextStyle.attributedStringWithText(comment.rawBody)
        
        if let item = DiscussionResponseItem(comment: comment) {
            authorLabel.attributedText = item.authorLabelForTextStyle(smallTextStyle)
        }
        self.containerView.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout([
            Icon.ReportFlag.attributedTextWithStyle(smallIconStyle),
            smallTextStyle.attributedStringWithText(Strings.discussionReport)])
        commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        commentCountOrReportIconButton.oex_removeAllActions()
        commentCountOrReportIconButton.oex_addAction({ _ -> Void in
            
            let apiRequest = DiscussionAPI.flagComment(comment.flagged, commentID: comment.commentID)
            viewController.environment.networkManager?.taskForRequest(apiRequest) { result in
                // TODO: update UI
            }
            }, forEvents: UIControlEvents.TouchUpInside)
        
        commentCountOrReportIconButton.setAttributedTitle(buttonTitle, forState: .Normal, animated : false)
        endorsed = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public extension UIButton {
    func setAttributedTitle(title : NSAttributedString, forState state: UIControlState, animated : Bool) {
        if !animated {
            UIView.performWithoutAnimation({ () -> Void in
                self.setAttributedTitle(title, forState: state)
                self.layoutIfNeeded()
            })
        }
        else {
            self.setAttributedTitle(title, forState: state)
        }
    }
}

class DiscussionCommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    class Environment {
        private var courseDataManager : CourseDataManager?
        private weak var router: OEXRouter?
        private var networkManager : NetworkManager?
        
        init(courseDataManager : CourseDataManager, router: OEXRouter?, networkManager : NetworkManager) {
            self.courseDataManager = courseDataManager
            self.router = router
            self.networkManager = networkManager
        }
    }
    
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
    private let discussionManager : DiscussionDataManager?
    
    private let addCommentButton = UIButton(type: .System)
    private var tableView: UITableView!
    private var comments : [DiscussionComment]  = []
    private let responseItem: DiscussionResponseItem
    
    //Since didSet doesn't get called from within initialization context, we need to set it with another variable.
    private var commentsClosed : Bool = false {
        didSet {
            let styles = OEXStyles.sharedStyles()
            
            addCommentButton.backgroundColor = commentsClosed ? styles.neutralBase() : styles.primaryXDarkColor()
            
            let textStyle = OEXTextStyle(weight : .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite())
            let icon = commentsClosed ? Icon.Closed : Icon.Create
            let buttonText = commentsClosed ? Strings.commentsClosed : Strings.addAComment
            let buttonTitle = NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(textStyle.withSize(.XSmall)), textStyle.attributedStringWithText(buttonText)])
            
            addCommentButton.setAttributedTitle(buttonTitle, forState: .Normal)
            addCommentButton.enabled = !commentsClosed
            
            if (!commentsClosed) {
                addCommentButton.oex_addAction({[weak self] (action : AnyObject!) -> Void in
                    if let owner = self {
                        owner.environment.router?.showDiscussionNewCommentFromController(owner, courseID: owner.courseID, item: DiscussionItem.Response(owner.responseItem))
                    }
                    }, forEvents: UIControlEvents.TouchUpInside)
            }
        }
    }
    
    //Only used to set commentsClosed out of initialization context
    //TODO: Get rid of this variable when Swift improves
    private var closed : Bool = false
    
    init(environment: Environment, courseID : String, responseItem: DiscussionResponseItem, closed : Bool) {
        self.courseID = courseID
        self.environment = environment
        self.responseItem = responseItem
        self.discussionManager = self.environment.courseDataManager?.discussionManagerForCourseWithID(self.courseID)
        self.closed = closed
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
        
        setStyles()
        addSubviews()
        setConstraints()
        
        discussionManager?.commentAddedStream.listen(self) {[weak self] result in
            result.ifSuccess {
                self?.addedItem($0.threadID, item: $0.comment)
            }
        }
        
        self.commentsClosed = self.closed
        
        self.comments = responseItem.children
        self.tableView.reloadData()
        
    }
    
    func addSubviews() {
        view.addSubview(addCommentButton)
        view.addSubview(tableView)
    }
    
    func setStyles() {
        
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.applyStandardSeparatorInsets()
        tableView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        tableView.contentInset = UIEdgeInsetsMake(10.0, 0, 0, 0)
        tableView.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        tableView.clipsToBounds = true
        
        self.navigationItem.title = Strings.comments
        view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        addCommentButton.contentVerticalAlignment = .Center
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }
    
    func setConstraints() {
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
    
    func addedItem(threadID: String, item: DiscussionComment) {
        self.comments.append(item)
        tableView.reloadData()
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
        
        // TODO: factor these into the cell classes
        switch TableSection(rawValue: indexPath.section) {
        case .Some(.Response):
            cell.useResponse(responseItem)
            return cell
        case .Some(.Comments):
            cell.useComment(comments[indexPath.row], inViewController: self)
            return cell
        case .None:
            assert(false, "Unknown table section")
            return UITableViewCell()
        }
    }
}
