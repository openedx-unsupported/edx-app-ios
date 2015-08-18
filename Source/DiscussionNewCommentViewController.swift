//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol DiscussionNewCommentViewControllerDelegate : class {
    func newCommentController(controller  : DiscussionNewCommentViewController, addedItem item: DiscussionResponseItem)
}

public class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    
    public class Environment {
        private let courseDataManager : CourseDataManager?
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        
        public init(courseDataManager : CourseDataManager, networkManager : NetworkManager?, router: OEXRouter?) {
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
        }
    }
    
    private let minBodyTextHeight: CGFloat = 66 // height for 3 lines of text
    private let environment: Environment
    
    private var addYourComment: String {
        return OEXLocalizedString("ADD_YOUR_COMMENT", nil)
    }
    private var addYourResponse: String {
        return OEXLocalizedString("ADD_YOUR_RESPONSE", nil)
    }
    
    weak var delegate: DiscussionNewCommentViewControllerDelegate?
    
    @IBOutlet private var scrollView: UIScrollView!

    @IBOutlet private var newCommentView: UIView!
    @IBOutlet private var answerTitle: UILabel!
    @IBOutlet private var answerBody: UILabel!
    @IBOutlet private var personTimeLabel: UILabel!
    @IBOutlet private var contentTextView: OEXPlaceholderTextView!
    @IBOutlet private var addCommentButton: UIButton!
    @IBOutlet private var contentTextViewHeightConstraint: NSLayoutConstraint!
    
    private let insetsController = ContentInsetsController()
    private let growingTextController = GrowingTextViewController()
    
    private let item: DiscussionItem
    private let courseID : String
    
    private var editingStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
        style.lineBreakMode = .ByWordWrapping
        return style
    }
    
    public init(environment: Environment, courseID : String, item: DiscussionItem) {
        self.environment = environment
        self.item = item
        self.courseID = courseID
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func addCommentTapped(sender: AnyObject) {
        // TODO convert to a spinner
        addCommentButton.enabled = false
        
        // create new response or comment
        
        let apiRequest = DiscussionAPI.createNewComment(item.threadID, text: contentTextView.text, parentID: item.responseID)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            
            if let comment = result.data,
                threadID = comment.threadId,
                courseID = self?.courseID {
                    let dataManager = self?.environment.courseDataManager?.discussionManagerForCourseWithID(courseID)
                    dataManager?.commentAddedStream.send((threadID: threadID, comment: comment))
                    
                    self?.dismissViewControllerAnimated(true, completion: nil)
            }
            else {
                // TODO: error handling
            }
        }
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .XSmall, color : OEXStyles.sharedStyles().neutralBase())
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewCommentView", owner: self, options: nil)
        view.addSubview(newCommentView)
        newCommentView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        switch item {
        case let .Post(post):
            answerTitle.attributedText = answerStyle.attributedStringWithText(item.title)
            
            addCommentButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: OEXLocalizedString("ADD_RESPONSE", nil))
            
            contentTextView.placeholder = addYourResponse
            self.navigationItem.title = OEXLocalizedString("RESPONSE", nil)
            
        case let .Response(response):
            answerTitle.attributedText = NSAttributedString.joinInNaturalLayout(
                before: Icon.Answered.attributedTextWithStyle(answerStyle),
                after: answerStyle.attributedStringWithText(OEXLocalizedString("ANSWER", nil)))
            addCommentButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: OEXLocalizedString("ADD_COMMENT", nil))

            // add place holder for the textview
            contentTextView.placeholder = addYourComment
            self.navigationItem.title = OEXLocalizedString("COMMENT", nil) 
        }
        personTimeLabel.text = item.createdAt.timeAgoSinceNow() +  " " + item.author

        answerBody.text = item.body
        
        answerTitle.textColor = OEXStyles.sharedStyles().utilitySuccessBase()
        answerBody.textColor = OEXStyles.sharedStyles().neutralDark()
                
        personTimeLabel.textColor = OEXStyles.sharedStyles().neutralBase()
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        contentTextView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = OEXStyles.sharedStyles().neutralLight()
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()
        contentTextView.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        contentTextView.delegate = self
        
        let tapGesture = UIGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.resignFirstResponder()
        }
        self.newCommentView.addGestureRecognizer(tapGesture)
        
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem

        self.addCommentButton.enabled = false
        
        self.insetsController.setupInController(self, scrollView: scrollView)
        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: addCommentButton)
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
    
}
