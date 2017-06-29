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
    
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider
    
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
    
    fileprivate let context: Context
    private let courseID : String
    private let thread: DiscussionThread?
    
    private var editingStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: .base, color: OEXStyles.shared().neutralDark())
        style.lineBreakMode = .byWordWrapping
        return style
    }
    
    private var isEndorsed : Bool = false {
        didSet {
            containerView.applyBorderStyle(style: BorderStyle())
            answerLabel.isHidden = !isEndorsed
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
        addCommentButton.isEnabled = false
        addCommentButton.showProgress = true
        // create new response or comment
        
        let apiRequest = DiscussionAPI.createNewComment(threadID: context.threadID, text: contentTextView.text, parentID: context.newCommentParentID)
        
        environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
            self?.addCommentButton.showProgress = false
            if let comment = result.data,
                let courseID = self?.courseID {
                    let dataManager = self?.environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID: courseID)
                    dataManager?.commentAddedStream.send((threadID: comment.threadID, comment: comment))
                    self?.delegate?.newCommentController(controller: self!, addedComment: comment)
                    self?.dismiss(animated: true, completion: nil)
            }
            else {
                self?.addCommentButton.isEnabled = true
                DiscussionHelper.showErrorMessage(controller: self, error: result.error)
            }
        }
    }
    
    private var responseTitleStyle : OEXTextStyle {
        return OEXTextStyle(weight : .normal, size : .large, color : OEXStyles.shared().neutralXDark())
    }
    
    private var answerLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().utilitySuccessBase())
    }
    
    private var responseTextViewStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    private var personTimeLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xxSmall, color: OEXStyles.shared().neutralBase())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.shared().discussionsBackgroundColor
        
        setupContext()
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = environment.styles.standardTextViewInsets
        contentTextView.typingAttributes = environment.styles.textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = environment.styles.neutralBase()
        contentTextView.textColor = environment.styles.neutralDark()
        contentTextView.applyBorderStyle(style: environment.styles.entryFieldBorderStyle)
        contentTextView.delegate = self
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.endEditing(true)
        }
        self.view.addGestureRecognizer(tapGesture)
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismiss(animated: true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem

        self.addCommentButton.isEnabled = false
        
        self.insetsController.setupInController(owner: self, scrollView: scrollView)
        self.growingTextController.setupWithScrollView(scrollView: scrollView, textView: contentTextView, bottomView: addCommentButton)
        
        DiscussionHelper.styleAuthorProfileImageView(imageView: authorProfileImage)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
        authorDetails()
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func logScreenEvent(){
        switch context {
        case let .Thread(thread):
            self.environment.analytics.trackDiscussionScreen(withName: AnalyticsScreenName.AddThreadResponse, courseId: self.courseID, value: thread.title, threadId: thread.threadID, topicId: thread.topicId, responseID: nil, author: thread.author)
        case let .Comment(comment):
            self.environment.analytics.trackDiscussionScreen(withName: AnalyticsScreenName.AddResponseComment, courseId: self.courseID, value: thread?.title, threadId: comment.threadID, topicId: nil, responseID: comment.commentID, author: comment.author)
        }
        
    }
    
    private func authorDetails() {
        switch context {
        case let .Comment(comment):
            DiscussionHelper.styleAuthorDetails(author: comment.author, authorLabel: comment.authorLabel, createdAt: comment.createdAt, hasProfileImage: comment.hasProfileImage, imageURL: comment.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(author: comment.author, date: comment.createdAt)
        case let .Thread(thread):
            DiscussionHelper.styleAuthorDetails(author: thread.author, authorLabel: thread.authorLabel, createdAt: thread.createdAt, hasProfileImage: thread.hasProfileImage, imageURL: thread.imageURL, authoNameLabel: authorNamelabel, dateLabel: dateLabel, authorButton: authorButton, imageView: authorProfileImage, viewController: self, router: environment.router)
            setAuthorAccessibility(author: thread.author, date: thread.createdAt)
        }
    }
    
    private func setAuthorAccessibility(author: String?, date: NSDate?) {
        if let author = author, let date = date {
            authorButton.accessibilityLabel = "\(Strings.byAuthor(authorName: author)), \(date.displayDate)"
            authorButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
        }
        
        dateLabel.isAccessibilityElement = false
        authorNamelabel.isAccessibilityElement = false
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        
        self.validateAddButton()
        self.growingTextController.handleTextChange()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
        self.growingTextController.scrollToVisible()
    }
    
    private func validateAddButton() {
        addCommentButton.isEnabled = !contentTextView.text.isEmpty
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
            responseTitle.attributedText = responseTitleStyle.attributedString(withText: thread.title)
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
        
        
        responseTextView.attributedText = responseTextViewStyle.markdownString(withText: context.renderedBody ?? "")
        
        addCommentButton.applyButtonStyle(style: environment.styles.filledPrimaryButtonStyle, withTitle: buttonTitle)
        self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [responseTextViewStyle.attributedString(withText: titleText), responseTextViewStyle.attributedString(withText: Strings.asteric)])
        self.contentTitleLabel.isAccessibilityElement = false
        self.navigationItem.title = navigationItemTitle
            
        if case .Comment(_) = self.context, let thread = thread{
            DiscussionHelper.updateEndorsedTitle(thread: thread, label: answerLabel, textStyle: answerLabelStyle)
        }
    }

}

extension DiscussionNewCommentViewController {
    
    public func currentContext() -> Context {
        return context
    }
}
