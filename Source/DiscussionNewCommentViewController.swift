//
//  DiscussionNewCommentViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/5/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionNewCommentViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}


class DiscussionNewCommentViewController: UIViewController, UITextViewDelegate {
    private var tapWrapper:UITapGestureRecognizerWithClosure?
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
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!

    @IBOutlet var newCommentView: UIView!
    @IBOutlet var answerLabel: UILabel!
    @IBOutlet var answerTextView: UITextView!
    @IBOutlet var personTimeLabel: UILabel!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var addCommentButton: UIButton!
    @IBOutlet var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var answerTextViewHeightConstraint: NSLayoutConstraint!
    
    var isResponse: Bool
    
    @IBAction func addCommentTapped(sender: AnyObject) {
    }
    
    
    init(env: DiscussionNewCommentViewControllerEnvironment, isResponse: Bool) {
        self.environment = env
        self.isResponse = isResponse
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        // TODO: validate user entry and submit to server
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(font : .ThemeSans, size : 12, color : OEXStyles.sharedStyles().neutralBase())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewCommentView", owner: self, options: nil)
        view.addSubview(newCommentView)
        newCommentView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newCommentView?.frame = view.frame
        
        if isResponse {
            answerLabel.attributedText = answerStyle.attributedStringWithText("Week 11 Tutorial") // TODO: replace with API result
            answerTextView.text = "The worked problem in the tutorial is \"not worked\", I mean there is only a link to the problem on the text book but nothing else. There isn't even the solution on the book appendix."
            personTimeLabel.text = "XXXXX 3 days ago Staff"
            addCommentButton.setTitle(OEXLocalizedString("ADD_RESPONSE", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = addAResponse
        }
        else {
            answerLabel.attributedText = NSAttributedString.joinInNaturalLayout(
                before: Icon.Answered.attributedTextWithStyle(answerStyle),
                after: answerStyle.attributedStringWithText(OEXLocalizedString("ANSWER", nil)))
            answerTextView.text = "Thanks ChrisRemsperger and mamba747 for the correction - since the contribution from R1 should not be dependent on frequency, R1 is still in series with R2 while the inductor behaves like an open circuit and the capacitor behaves like a short circuit, so ther answer to part 2 of version B should indeed be R1 + R2. This has been corrected."
            personTimeLabel.text = "YYYYY 3 days ago Staff"
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
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newCommentView, tapGestureRecognizer: UITapGestureRecognizer()) {
            [weak self] in
            self?.contentTextView.resignFirstResponder()
        }
        
        handleKeyboard(scrollView, backgroundView)
    }
    
    func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
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
