//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol DiscussionNewCommentViewControllerDelegate : class {
    func newCommentControllerAddedItem(item: DiscussionResponseItem)
}

class DiscussionNewCommentViewControllerEnvironment {
    weak var router: OEXRouter?
    let networkManager : NetworkManager?
    
    init(networkManager : NetworkManager, router: OEXRouter?) {
        self.networkManager = networkManager
        self.router = router
    }
}


class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    private let MIN_HEIGHT: CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewCommentViewControllerEnvironment
    private var addAComment: String {
        get {
            return OEXLocalizedString("ADD_A_COMMENT", nil)
        }
    }
    private var addAResponse: String {
        get {
            return OEXLocalizedString("ADD_A_RESPONSE", nil)
        }
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
    
    private let isResponse: Bool
    private var responseItem : DiscussionResponseItem? // used to hold the newly created comment/response to update UI without making an extra API call
    private let item: DiscussionItem // set in DiscussionNewCommentViewController initializer when "Add a response" or "Add a comment" is tapped
    
    
    init(env: DiscussionNewCommentViewControllerEnvironment, isResponse: Bool, item: DiscussionItem) {
        self.environment = env
        self.isResponse = isResponse
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @IBAction func addCommentTapped(sender: AnyObject) {
        addCommentButton.enabled = false
        
        // create new response or comment
        
        var json = JSON([
            "thread_id" : item.threadID,  //isResponse ? (item as! DiscussionPostItem).threadID : (item as! DiscussionResponseItem).threadID,
            "raw_body" : contentTextView.text,
            ])
        if !isResponse {
            json["parent_id"] = JSON(item.responseID)
        }
        
        let apiRequest = DiscussionAPI.createNewComment(json)
        
        environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
            self?.navigationController?.popViewControllerAnimated(true)
            self?.addCommentButton.enabled = false
            
            // TODO: error handling
            if let comment: DiscussionComment = result.data {
                if  let body = comment.rawBody,
                    author = comment.author,
                    createdAt = comment.createdAt,
                    responseID = comment.identifier,
                    threadID = comment.threadId {
                        
                        let voteCount = comment.voteCount
                        
                        self?.responseItem = DiscussionResponseItem(
                            body: body,
                            author: author,
                            createdAt: createdAt,
                            voteCount: voteCount,
                            responseID: responseID,
                            threadID: threadID,
                            flagged: comment.flagged,
                            voted: comment.voted,
                            children: [])
                }
            }
            
            if let responseItem = self?.responseItem {
                self?.delegate?.newCommentControllerAddedItem(responseItem)
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
        
        if isResponse {
            answerLabel.attributedText = answerStyle.attributedStringWithText(item.title)
            answerTextView.text = item.body
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            addCommentButton.setTitle(OEXLocalizedString("ADD_RESPONSE", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = addAResponse
        }
        else {
            answerLabel.attributedText = NSAttributedString.joinInNaturalLayout(
                before: Icon.Answered.attributedTextWithStyle(answerStyle),
                after: answerStyle.attributedStringWithText(OEXLocalizedString("ANSWER", nil)))
            answerTextView.text = item.body
            personTimeLabel.text = DateHelper.socialFormatFromDate(item.createdAt) +  " " + item.author
            addCommentButton.setTitle(OEXLocalizedString("ADD_COMMENT", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = addAComment
        }
        answerLabel.textColor = OEXStyles.sharedStyles().utilitySuccessBase()
        answerTextView.textColor = OEXStyles.sharedStyles().neutralDark()
        
        let fixedWidth = answerTextView.frame.size.width
        let newSize = answerTextView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        answerTextViewHeightConstraint.constant = newSize.height
        
        personTimeLabel.textColor = OEXStyles.sharedStyles().neutralBase()
        
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()
        
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        contentTextView.layer.cornerRadius = 10
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
        if textView.text == addAComment || textView.text == addAResponse {
            textView.text = ""
            textView.textColor = OEXStyles.sharedStyles().neutralBlack()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = isResponse ? addAResponse : addAComment
            textView.textColor = OEXStyles.sharedStyles().neutralLight()
        }
        textView.resignFirstResponder()
    }
    
}
