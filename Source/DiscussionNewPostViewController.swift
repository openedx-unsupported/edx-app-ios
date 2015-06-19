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


class UITapGestureRecognizerWithClosure: NSObject {
    var closure: () -> ()
    
    init(view: UIView, tapGestureRecognizer: UITapGestureRecognizer, closure: () -> ()) {
        self.closure = closure
        super.init()
        view.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.addTarget(self, action:Selector("actionFired:"))
    }
    
    func actionFired(tapGestureRecognizer: UITapGestureRecognizer) {
        self.closure()
    }
}

class DiscussionNewPostViewController: DiscussionNewViewController, UITextViewDelegate {
    
    private var tapWrapper:UITapGestureRecognizerWithClosure?
    
    private let MIN_HEIGHT : CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewPostViewControllerEnvironment

    @IBOutlet var newPostView: UIView!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topicButton: UIButton!
    @IBOutlet var postDiscussionButton: UIButton!
    
    
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
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("DISCUSSION", nil), forSegmentAtIndex: 0)
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("QUESTION", nil), forSegmentAtIndex: 1)
        titleTextField.placeholder = OEXLocalizedString("TITLE", nil)
        topicButton.setTitle(OEXLocalizedString("TOPIC", nil), forState: .Normal)
        postDiscussionButton.setTitle(OEXLocalizedString("POST_DISCUSSION", nil), forState: .Normal)
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newPostView, tapGestureRecognizer: UITapGestureRecognizer()) {
            self.contentTextView.resignFirstResponder()
            self.titleTextField.resignFirstResponder()
        }
        
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "viewTapped:")
//        view.addGestureRecognizer(tapGestureRecognizer)
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        handleKeyboard()
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
