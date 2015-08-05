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

class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    
    class Environment {
        private let courseDataManager : CourseDataManager?
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        
        init(courseDataManager : CourseDataManager, networkManager : NetworkManager, router: OEXRouter?) {
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
        }
    }
    
    private let MIN_HEIGHT: CGFloat = 66 // height for 3 lines of text
    private let environment: Environment
    
    private var addYourComment: String {
        return OEXLocalizedString("ADD_YOUR_COMMENT", nil)
    }
    private var addYourResponse: String {
        return OEXLocalizedString("ADD_YOUR_RESPONSE", nil)
    }
    
    weak var delegate: DiscussionNewCommentViewControllerDelegate?
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var backgroundView: UIView!

    @IBOutlet private var newCommentView: UIView!
    @IBOutlet private var answerLabel: UILabel!
    @IBOutlet private var answerTextView: UITextView!
    @IBOutlet private var personTimeLabel: UILabel!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var addCommentButton: UIButton!
    @IBOutlet private var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var answerTextViewHeightConstraint: NSLayoutConstraint!
    
    private let item: DiscussionItem // set in DiscussionNewCommentViewController initializer when "Add a response" or "Add a comment" is tapped
    private let courseID : String
    
    init(environment: Environment, courseID : String, item: DiscussionItem) {
        self.environment = environment
        self.item = item
        self.courseID = courseID
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func addCommentTapped(sender: AnyObject) {
        addCommentButton.enabled = false
        
        // create new response or comment
        
        let apiRequest = DiscussionAPI.createNewComment(item.threadID, text: contentTextView.text, parentID: item.responseID)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            
            if let comment = result.data,
                threadID = comment.threadId,
                courseID = self?.courseID {
                    let dataManager = self?.environment.courseDataManager?.discussionManagerForCourseWithID(courseID)
                    dataManager?.commentAddedStream.send((threadID: threadID, comment: comment))
                    
                    self?.navigationController?.popViewControllerAnimated(true)
            }
            else {
                // TODO: error handling
            }
        }
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size : .XSmall, color : OEXStyles.sharedStyles().neutralBase())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewCommentView", owner: self, options: nil)
        view.addSubview(newCommentView)
        newCommentView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newCommentView?.frame = view.frame
        
        switch item {
        case let .Post(post):
            answerLabel.attributedText = answerStyle.attributedStringWithText(item.title)
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            
            addCommentButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size : .Small, color : OEXStyles.sharedStyles().neutralWhite()).attributedStringWithText(OEXLocalizedString("ADD_RESPONSE", nil)), forState: .Normal)
            
            // add place holder for the textview
            contentTextView.text = addYourResponse
            self.navigationItem.title = OEXLocalizedString("RESPONSE", nil)
        case let .Response(response):
            answerLabel.attributedText = NSAttributedString.joinInNaturalLayout(
                before: Icon.Answered.attributedTextWithStyle(answerStyle),
                after: answerStyle.attributedStringWithText(OEXLocalizedString("ANSWER", nil)))
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            addCommentButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size : .Small, color : OEXStyles.sharedStyles().neutralWhite()).attributedStringWithText(OEXLocalizedString("ADD_COMMENT", nil)), forState: .Normal)

            // add place holder for the textview
            contentTextView.text = addYourComment
            self.navigationItem.title = OEXLocalizedString("COMMENT", nil) 
        }
        answerTextView.text = item.body
        
        addCommentButton.backgroundColor = OEXStyles.sharedStyles().primaryBaseColor()
        addCommentButton.setTitleColor(OEXStyles.sharedStyles().neutralWhite(), forState: .Normal)
        addCommentButton.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        addCommentButton.layer.masksToBounds = true
        
        answerLabel.textColor = OEXStyles.sharedStyles().utilitySuccessBase()
        answerTextView.textColor = OEXStyles.sharedStyles().neutralDark()
        
        let fixedWidth = answerTextView.frame.size.width
        let newSize = answerTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        answerTextViewHeightConstraint.constant = newSize.height
        
        personTimeLabel.textColor = OEXStyles.sharedStyles().neutralBase()
        
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()
        
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        contentTextView.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        contentTextView.layer.masksToBounds = true
        contentTextView.delegate = self
        
        let tapGesture = UIGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.resignFirstResponder()
        }
        self.newCommentView.addGestureRecognizer(tapGesture)
        
        handleKeyboard(scrollView, backgroundView)
    }
    
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        if newSize.height >= MIN_HEIGHT {
            contentTextViewHeightConstraint.constant = newSize.height
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == addYourComment || textView.text == addYourResponse {
            textView.text = ""
            textView.textColor = OEXStyles.sharedStyles().neutralBlack()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = item.isResponse ? addYourResponse : addYourComment
            textView.textColor = OEXStyles.sharedStyles().neutralLight()
        }
    }
    
}
