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
    
    private let ANSWER_LABEL_VISIBLE_HEIGHT : CGFloat = 15
    
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
    
    private let insetsController = ContentInsetsController()
    private let growingTextController = GrowingTextViewController()
    
    private let ownerItem: DiscussionItem
    private let courseID : String
    
    private var editingStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
        style.lineBreakMode = .ByWordWrapping
        return style
    }
    
    private var isEndorsed : Bool = false {
        didSet {
            containerView.applyBorderStyle(isEndorsed ? OEXStyles.sharedStyles().endorsedPostBorderStyle : BorderStyle())
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
    
    public init(environment: Environment, courseID : String, item: DiscussionItem) {
        self.environment = environment
        self.ownerItem = item
        self.courseID = courseID
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
        
        let apiRequest = DiscussionAPI.createNewComment(ownerItem.threadID, text: contentTextView.text, parentID: ownerItem.responseID)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            self?.addCommentButton.showProgress = false
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
    
    private var responseTitleStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .Base, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var answerLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().utilitySuccessBase())
    }
    
    private var responseBodyStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var personTimeLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XXXSmall, color: OEXStyles.sharedStyles().neutralBase())
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
        
        switch ownerItem {
        case .Post(_):
            buttonTitle = Strings.addResponse
            placeholderText = Strings.addAResponse
            navigationItemTitle = Strings.addResponse
        case .Response(_):
            buttonTitle = Strings.addComment
            placeholderText = Strings.addAComment
            navigationItemTitle = Strings.addComment
            responseTitle.snp_makeConstraints{ (make) -> Void in
                make.height.equalTo(0)
            }
        }
        
        self.isEndorsed = ownerItem.isEndorsed
        
        responseTitle.attributedText = responseTitleStyle.attributedStringWithText(ownerItem.title)
        responseBody.attributedText = responseBodyStyle.attributedStringWithText(ownerItem.body)
        
        addCommentButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: buttonTitle)
        contentTextView.placeholder = placeholderText
        self.navigationItem.title = navigationItemTitle
        
        answerLabel.attributedText = NSAttributedString.joinInNaturalLayout([
            Icon.Answered.attributedTextWithStyle(answerLabelStyle, inline : true),
                            answerLabelStyle.attributedStringWithText(Strings.answer)])

        personTimeLabel.attributedText = ownerItem.authorLabelForTextStyle(personTimeLabelStyle)
    }
    

}
