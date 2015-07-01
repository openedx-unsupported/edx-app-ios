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

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate {
    
    private var tapWrapper:UITapGestureRecognizerWithClosure?
    
    private let MIN_HEIGHT : CGFloat = 66 // height for 3 lines of text
    private let environment: DiscussionNewPostViewControllerEnvironment
    private let insetsController = ContentInsetsController()
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!

    @IBOutlet var newPostView: UIView!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topicButton: UIButton!
    @IBOutlet var postDiscussionButton: UIButton!
    private let course: OEXCourse
    private let postsVC: PostsViewController
    
    init(env: DiscussionNewPostViewControllerEnvironment, postsVC: PostsViewController) { 
        self.environment = env
        self.course = postsVC.course
        self.postsVC = postsVC
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postDiscussionButton.enabled = false
        // create new thread (post)
        // TODO: get topic ID from the selected topic name
        
        let json = JSON([
            "course_id" : course.course_id,
            "topic_id" : "b770140a122741fea651a50362dee7e6", // TODO: replace this with real topic ID, selectable from the Topic dropdown in Create a new post UI.
            "type" : "discussion",
            "title" : titleTextField.text,
            "raw_body" : contentTextView.text,
            ])
        
        let apiRequest = DiscussionAPI.createNewThread(json)        
        environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
            // result.data is optional DiscussionThread; result.data!.title 
            self.navigationController?.popViewControllerAnimated(true)
            self.postDiscussionButton.enabled = true
        }
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
        topicButton.setTitle(postsVC.topicsVC.selectedTopic, forState: .Normal)
        
        weak var weakSelf = self
        topicButton.oex_addAction({ (action : AnyObject!) -> Void in
            // TODO: replace the code below and show postsVC.topicsVC.topicsArray in native UI
            if let topics = weakSelf!.postsVC.topicsVC.topics {
                for topic in topics {
                    println(">>>> \(topic.name)")
                    if topic.children != nil {
                        for child in topic.children! {
                            println("     \(child.name)")
                        }
                    }
                }
            }
        }, forEvents: UIControlEvents.TouchUpInside)
        
        postDiscussionButton.setTitle(OEXLocalizedString("POST_DISCUSSION", nil), forState: .Normal)
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newPostView, tapGestureRecognizer: UITapGestureRecognizer()) {
            self.contentTextView.resignFirstResponder()
            self.titleTextField.resignFirstResponder()
        }

        self.insetsController.setupInController(self, scrollView: scrollView)

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
