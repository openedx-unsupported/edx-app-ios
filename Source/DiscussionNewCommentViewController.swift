//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol DiscussionNewCommentViewControllerDelegate : class {
    func newCommentController(controller  : DiscussionNewCommentViewController, addedComment comment: DiscussionComment)
}

public class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    
    public typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider>
    
    public enum Context {
        case Thread(DiscussionThread)
        case Comment(DiscussionComment)
        
        var threadID: String {
            switch self {
            case let .Thread(thread): return thread.threadID
            case let .Comment(comment): return comment.threadID
            }
        }
        
        var rawBody: String? {
            switch self {
            case let .Thread(thread): return thread.rawBody
            case let .Comment(comment): return comment.rawBody
            }
        }
        
        var newCommentParentID: String? {
            switch self {
            case .Thread(_): return nil
            case let .Comment(comment): return comment.commentID
            }
        }
        
        var author: String? {
            switch self {
            case let .Thread(thread): return thread.author
            case let .Comment(comment): return comment.author
            }
        }
        
        func authorLabelForTextStyle(style : OEXTextStyle) -> NSAttributedString {
            switch self {
            case let .Thread(thread): return thread.formattedUserLabel(style)
            case let .Comment(comment): return comment.formattedUserLabel(style)
            }
        }
        
        func endorsedLabelForTextStyle(style : OEXTextStyle, type: DiscussionThreadType) -> NSAttributedString? {
            switch self {
            case .Thread(_): return nil
            case let .Comment(comment): return comment.formattedUserLabel(comment.endorsedBy, date: comment.endorsedAt, label: comment.endorsedByLabel, endorsedLabel: true, threadType: type, textStyle: style)
            }
        }
        
    }
    
    private let ANSWER_LABEL_VISIBLE_HEIGHT : CGFloat = 15
    
    private let minBodyTextHeight: CGFloat = 66 // height for 3 lines of text
    private let environment: Environment
    
    weak var delegate: DiscussionNewCommentViewControllerDelegate?
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var responseTitle: UILabel!
    @IBOutlet private var answerLabel: UILabel!
    @IBOutlet private var responseBody: UILabel!
    @IBOutlet private var personTimeLabel: UILabel!
    @IBOutlet private var contentTextView: OEXPlaceholderTextView!
    @IBOutlet private var addCommentButton: SpinnerButton!
    @IBOutlet private var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var authorButton: UIButton!
    @IBOutlet private var viewHeight: NSLayoutConstraint!
    
    private let insetsController = ContentInsetsController()
    private let growingTextController = GrowingTextViewController()
    
    private let context: Context
    private let courseID : String
    private let thread: DiscussionThread?
    
    private var editingStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
        style.lineBreakMode = .ByWordWrapping
        return style
    }
    
    private var isEndorsed : Bool = false {
        didSet {
            containerView.applyBorderStyle(BorderStyle())
            answerLabel.hidden = !isEndorsed
            
            responseTitle.snp_updateConstraints { (make) -> Void in
                if isEndorsed {
                    make.top.equalTo(answerLabel.snp_bottom)
                }
                else {
                    make.top.equalTo(containerView).offset(8)
                }
            }
        }
    }
    
    public init(environment: Environment, courseID : String, thread: DiscussionThread?, context: Context) {
        self.environment = environment
        self.context = context
        self.courseID = courseID
        self.thread = thread
        super.init(nibName: "DiscussionNewCommentViewController", bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func addCommentTapped(sender: AnyObject) {
        // TODO convert to a spinner
        addCommentButton.enabled = false
        addCommentButton.showProgress = true
        // create new response or comment
        
        let apiRequest = DiscussionAPI.createNewComment(context.threadID, text: contentTextView.text, parentID: context.newCommentParentID)
        
        environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            self?.addCommentButton.showProgress = false
            if let comment = result.data,
                courseID = self?.courseID {
                    let dataManager = self?.environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID)
                    dataManager?.commentAddedStream.send((threadID: comment.threadID, comment: comment))
                    self?.delegate?.newCommentController(self!, addedComment: comment)
                    self?.dismissViewControllerAnimated(true, completion: nil)
            }
            else {
                self?.addCommentButton.enabled = true
                self?.showOverlayMessage(DiscussionHelper.getErrorMessage(result.error))
            }
        }
    }
    
    private var responseTitleStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .Large, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var answerLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    private var responseBodyStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var personTimeLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        
        setupContext()
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        contentTextView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = OEXStyles.sharedStyles().neutralLight()
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()
        contentTextView.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        contentTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.endEditing(true)
        }
        self.view.addGestureRecognizer(tapGesture)
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem

        self.addCommentButton.enabled = false
        
        self.insetsController.setupInController(self, scrollView: scrollView)
        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: addCommentButton)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
    }
    
    private func logScreenEvent(){
        switch context {
        case let .Thread(thread):
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenAddThreadResponse, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil)
        case let .Comment(comment):
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenAddResponseComment, courseId: self.courseID, value: thread?.title, threadId: comment.threadID, topicId: nil, responseID: comment.commentID)
        }
        
    }
    
    public func textViewDidChange(textView: UITextView) {
        self.validateAddButton()
        self.growingTextController.handleTextChange()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
        self.growingTextController.scrollToVisible()
    }
    
    private func validateAddButton() {
        addCommentButton.enabled = !contentTextView.text.isEmpty
    }
    
    // For determining the context of the screen and also manipulating the relevant elements on screen
    private func setupContext() {
        let buttonTitle : String
        let placeholderText : String
        let navigationItemTitle : String
        
        switch context {
        case let .Thread(thread):
            buttonTitle = Strings.addResponse
            placeholderText = Strings.addAResponse
            navigationItemTitle = Strings.addResponse
            responseTitle.attributedText = responseTitleStyle.attributedStringWithText(thread.title)
            self.isEndorsed = false
        case let .Comment(comment):
            buttonTitle = Strings.addComment
            placeholderText = Strings.addAComment
            navigationItemTitle = Strings.addComment
            responseTitle.snp_makeConstraints{ (make) -> Void in
                make.height.equalTo(0)
            }
            self.isEndorsed = comment.endorsed
        }
        
        
        responseBody.attributedText = responseBodyStyle.attributedStringWithText(context.rawBody)
        
        addCommentButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: buttonTitle)
        contentTextView.placeholder = placeholderText
        self.navigationItem.title = navigationItemTitle
            
        if case .Comment(_) = self.context, let thread = thread{
            DiscussionHelper.updateEndorsedTitle(thread, label: answerLabel, textStyle: answerLabelStyle)
        }
        
        DiscussionHelper.styleAuthorButton(authorButton, title: context.authorLabelForTextStyle(personTimeLabelStyle), author: self.context.author, viewController: self, router: self.environment.router)
    }

}

extension DiscussionNewCommentViewController {
    
    public func currentContext() -> Context {
        return context
    }
}
