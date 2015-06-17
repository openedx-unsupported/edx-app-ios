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
    
    @IBOutlet var newCommentView: UIView!
    @IBOutlet weak var newCommentScrollView: UIScrollView!
    @IBOutlet weak var answerLabel: UILabel!
    @IBOutlet weak var answerTextView: UITextView!
    @IBOutlet weak var personTimeLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var addCommentButton: UIButton!
    @IBOutlet weak var contentTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var answerTextViewHeightConstraint: NSLayoutConstraint!
    
    var isResponse: NSNumber? // Bool would be more appropriate, but optional values of non-Objective-C types aren't bridged into Objective-C.
    
    @IBAction func addCommentTapped(sender: AnyObject) {
    }
    
    
    init(env: DiscussionNewCommentViewControllerEnvironment) {
        self.environment = env
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        // TODO: validate user entry and submit to server
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewCommentView", owner: self, options: nil)
        view.addSubview(newCommentView)
        newCommentView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newCommentView?.frame = view.frame
        
        if isResponse?.integerValue == 0 {
            answerLabel.font = Icon.fontWithSize(12)
            if UIApplication.sharedApplication().userInterfaceLayoutDirection == .LeftToRight {
                answerLabel.text = Icon.Answered.textRepresentation + " " + OEXLocalizedString("ANSWER", nil)
            }
            else {
                answerLabel.text = OEXLocalizedString("ANSWER", nil) + " " + Icon.Answered.textRepresentation
            }
        }
        else {
            answerLabel.text = "Week 11 Tutorial" // TODO: replace with API result
        }
        answerLabel.textColor = OEXStyles.sharedStyles().utilitySuccessBase()
        
        // TODO: replace text with API return
        if isResponse?.integerValue == 0 {
            answerTextView.text = "Thanks ChrisRemsperger and mamba747 for the correction - since the contribution from R1 should not be dependent on frequency, R1 is still in series with R2 while the inductor behaves like an open circuit and the capacitor behaves like a short circuit, so ther answer to part 2 of version B should indeed be R1 + R2. This has been corrected."
            personTimeLabel.text = "BonnieKYLam 3 days ago Staff"
            addCommentButton.setTitle(OEXLocalizedString("ADD_COMMENT", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = OEXLocalizedString("ADD_A_COMMENT", nil)
        }
        else {
            answerTextView.text = "The worked problem in the tutorial is \"not worked\", I mean there is only a link to the problem on the text book but nothing else. There isn't even the solution on the book appendix."
            personTimeLabel.text = "ChrisRemsperger 3 days ago Staff"
            addCommentButton.setTitle(OEXLocalizedString("ADD_RESPONSE", nil), forState: .Normal)
            // add place holder for the textview
            contentTextView.text = OEXLocalizedString("ADD_A_RESPONSE", nil)
        }
        
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
            self.contentTextView.resignFirstResponder()
        }
        
        //        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        //        view.addGestureRecognizer(tapGestureRecognizer)

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, notification: UIKeyboardWillChangeFrameNotification) { (notification : NSNotification!, observer : AnyObject!, removeable : OEXRemovable!) -> Void in
            if let vc = observer as? DiscussionNewCommentViewController{
                if let info = notification.userInfo {
                    let keyboardEndRectObject = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
                    var keyboardEndRect = keyboardEndRectObject.CGRectValue()
                    keyboardEndRect = self.view.convertRect(keyboardEndRect, fromView: nil)
                    let intersectionOfKeyboardRectAndWindowRect = CGRectIntersection(self.view.frame, keyboardEndRect)
                    self.newCommentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: intersectionOfKeyboardRectAndWindowRect.size.height, right: 0)
                    if self.newCommentScrollView.contentOffset.y == 0 {
                        self.newCommentScrollView.contentOffset = CGPointMake(0, self.backgroundView.frame.origin.y)
                    }
                    else {
                        self.newCommentScrollView.contentOffset = CGPointZero
                    }
                }
                
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
        if textView.text == OEXLocalizedString("ADD_A_COMMENT", nil) {
            textView.text = ""
            textView.textColor = OEXStyles.sharedStyles().neutralBlack()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = OEXLocalizedString("ADD_A_COMMENT", nil)
            textView.textColor = OEXStyles.sharedStyles().neutralLight()
        }
        textView.resignFirstResponder()
    }
    
}
