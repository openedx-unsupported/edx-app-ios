//
//  DiscussionNewPostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class DiscussionNewPostViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    
    init(router: OEXRouter?) {
        self.router = router
    }
}

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate {
    
    private let MIN_HEIGHT : CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewPostViewControllerEnvironment
    
    @IBOutlet var newPostView: UIView!
    @IBOutlet weak var newPostScrollView: UIScrollView!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var titleBodyBackgroundView: UIView!
    @IBOutlet weak var titleTextField: UITextField!    
    @IBOutlet weak var dQSegControl: UISegmentedControl!
    @IBOutlet weak var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topicButton: UIButton!    
    @IBOutlet weak var postDiscussionButton: UIButton!
    
    init(env: DiscussionNewPostViewControllerEnvironment) {
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
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewPostView", owner: self, options: nil)
        view.addSubview(newPostView)
        newPostView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newPostView?.frame = view.frame
        
        contentTextView.layer.cornerRadius = 10
        contentTextView.layer.masksToBounds = true
        contentTextView.delegate = self
        
        dQSegControl.setTitle(OEXLocalizedString("DISCUSSION", nil), forSegmentAtIndex: 0)
        dQSegControl.setTitle(OEXLocalizedString("QUESTION", nil), forSegmentAtIndex: 1)
        titleTextField.placeholder = OEXLocalizedString("TITLE", nil)
        topicButton.setTitle(OEXLocalizedString("TOPIC", nil), forState: .Normal)
        postDiscussionButton.setTitle(OEXLocalizedString("POST_DISCUSSION", nil), forState: .Normal)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().oex_addObserver(self, notification: UIKeyboardWillChangeFrameNotification) { (notification : NSNotification!, observer : AnyObject!, removeable : OEXRemovable!) -> Void in
            if let vc = observer as? DiscussionNewPostViewController{
                if let info = notification.userInfo {
                    let keyboardEndRectObject = info[UIKeyboardFrameEndUserInfoKey] as! NSValue
                    var keyboardEndRect = CGRectZero
                    keyboardEndRectObject.getValue(&keyboardEndRect)
                    let window = UIApplication.sharedApplication().keyWindow
                    keyboardEndRect = self.view.convertRect(keyboardEndRect, fromView: window)
                    let intersectionOfKeyboardRectAndWindowRect = CGRectIntersection(self.view.frame, keyboardEndRect)
                    self.newPostScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: intersectionOfKeyboardRectAndWindowRect.size.height, right: 0)
                    if self.newPostScrollView.contentOffset.y == 0 {
                        self.newPostScrollView.contentOffset = CGPointMake(0, self.titleTextField.frame.origin.y + self.titleBodyBackgroundView.frame.origin.y)
                    }
                    else {
                        self.newPostScrollView.contentOffset = CGPointZero
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
        titleTextField.resignFirstResponder()
    }
    
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        if newSize.height >= MIN_HEIGHT {
            bodyTextViewHeightConstraint.constant = newSize.height
        }
    }
}
