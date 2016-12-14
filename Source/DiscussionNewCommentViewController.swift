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

public class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate, InterfaceOrientationOverriding {
    
    public typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider, OEXStylesProvider>
    
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
        
        var renderedBody: String? {
            switch self {
            case let .Thread(thread): return thread.renderedBody
            case let .Comment(comment): return comment.renderedBody
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
    }

    private let environment: Environment
    
    weak var delegate: DiscussionNewCommentViewControllerDelegate?
    
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var responseTitle: UILabel!
    @IBOutlet private var answerLabel: UILabel!
    @IBOutlet private var responseTextView: UITextView!
    @IBOutlet private var contentTextView: OEXPlaceholderTextView!
    @IBOutlet private var addCommentButton: SpinnerButton!
    @IBOutlet private var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet private var authorButton: UIButton!
    @IBOutlet weak var authorNamelabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var authorProfileImage: UIImageView!
    
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
                make.top.equalTo(authorProfileImage.snp_bottom).offset(StandardVerticalMargin)
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
                self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
            }
        }
    }
    
    private var responseTitleStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .Large, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var answerLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    private var responseTextViewStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var personTimeLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXSmall, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.sharedStyles().discussionsBackgroundColor
        
        setupContext()
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = environment.styles.standardTextViewInsets
        contentTextView.typingAttributes = environment.styles.textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = environment.styles.neutralBase()
        contentTextView.textColor = environment.styles.neutralDark()
        contentTextView.applyBorderStyle(environment.styles.entryFieldBorderStyle)
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
        
        DiscussionHelper.styleAuthorProfileImageView(authorProfileImage)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
        authorDetails()
    }
    
    override public func shouldAutorotate() -> Bool {
        return true
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    private func logScreenEvent(){
        switch context {
        case let .Thread(thread):
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenAddThreadResponse, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil)
        case let .Comment(comment):
            self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenAddResponseComment, courseId: self.courseID, value: thread?.title, threadId: comment.threadID, topicId: nil, responseID: comment.commentID)
        }
        
    }
    
    private func authorDetails() {
        switch context {
        case let .Comment(comment):
            DiscussionHelper.styleAuthorDetails(comment.author, authorLabel: comment.authorLabel, createdAt: comment.createdAt, hasProfileImage: comment.hasProfileImage, imageURL: comment.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(comment.author, date: comment.createdAt)
        case let .Thread(thread):
            DiscussionHelper.styleAuthorDetails(thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(thread.author, date: thread.createdAt)
        }
    }
    
    private func setAuthorAccessibility(author: String?, date: NSDate?) {
        if let author = author, date = date {
            authorButton.accessibilityLabel = "\(Strings.byAuthor(authorName: author)), \(date.displayDate)"
            authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
        
        dateLabel.isAccessibilityElement = false
        authorNamelabel.isAccessibilityElement = false
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
        let titleText : String
        let navigationItemTitle : String
        
        switch context {
        case let .Thread(thread):
            buttonTitle = Strings.addResponse
            titleText = Strings.addAResponse
            navigationItemTitle = Strings.addResponse
            responseTitle.attributedText = responseTitleStyle.attributedStringWithText(thread.title)
            contentTextView.accessibilityLabel = Strings.addAResponse
            self.isEndorsed = false
        case let .Comment(comment):
            buttonTitle = Strings.addComment
            titleText = Strings.addAComment
            navigationItemTitle = Strings.addComment
            contentTextView.accessibilityLabel = Strings.addAComment
            responseTitle.snp_makeConstraints{ (make) -> Void in
                make.height.equalTo(0)
            }
            self.isEndorsed = comment.endorsed
        }
        
        
        responseTextView.attributedText = responseTextViewStyle.markdownStringWithText(context.renderedBody ?? "")
        
        addCommentButton.applyButtonStyle(environment.styles.filledPrimaryButtonStyle, withTitle: buttonTitle)
        self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([responseTextViewStyle.attributedStringWithText(titleText), responseTextViewStyle.attributedStringWithText(Strings.asteric)])
        self.contentTitleLabel.isAccessibilityElement = false
        self.navigationItem.title = navigationItemTitle
            
        if case .Comment(_) = self.context, let thread = thread{
            DiscussionHelper.updateEndorsedTitle(thread, label: answerLabel, textStyle: answerLabelStyle)
        }
    }

}

extension DiscussionNewCommentViewController {
    
    public func currentContext() -> Context {
        return context
    }
}
