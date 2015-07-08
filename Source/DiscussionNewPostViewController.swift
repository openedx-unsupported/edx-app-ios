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

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsDelegate {
    
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
    
    private let topicsArray: [String]
    private let topics: [Topic]
    private var selectedTopic: String
    private var selectedTopicID: String?
    private var selectedTopicIndex = 0
    
    var viewControllerOption: MenuOptionsViewController!
    
    init(env: DiscussionNewPostViewControllerEnvironment, course: OEXCourse, selectedTopic: String, topics: [Topic], topicsArray: [String]) {
        self.environment = env
        self.course = course
        self.selectedTopic = selectedTopic
        self.topics = topics
        self.topicsArray = topicsArray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postDiscussionButton.enabled = false
        // create new thread (post)
        // TODO: get topic ID from the selected topic name
        
        if let topicID = selectedTopicID {
            let json = JSON([
                "course_id" : course.course_id,
                "topic_id" : topicID,
                "type" : "discussion",
                "title" : titleTextField.text,
                "raw_body" : contentTextView.text,
                ])
            
            let apiRequest = DiscussionAPI.createNewThread(json)
            environment.router?.environment.networkManager.taskForRequest(apiRequest) { result in
                self.navigationController?.popViewControllerAnimated(true)
                self.postDiscussionButton.enabled = true
            }
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
        BorderStyle(cornerRadius: OEXStyles.sharedStyles().boxCornerRadius(), width: .Size(1), color: OEXStyles.sharedStyles().neutralXLight()).applyToView(topicButton)

        topicButton.setTitle(NSString(format: OEXLocalizedString("TOPIC", nil), selectedTopic) as String, forState: .Normal)
        let dropdownLabel = UILabel()
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBase())
        dropdownLabel.attributedText = Icon.Dropdown.attributedTextWithStyle(style.withSize(.XSmall))
        topicButton.addSubview(dropdownLabel)
        dropdownLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(topicButton).offset(-5)
            make.top.equalTo(topicButton).offset(topicButton.frame.size.height / 2.0 - 5.0)
        }
        
        setSelectedTopicID()
        
        topicButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            if let owner = self {
                if owner.viewControllerOption != nil {
                    return
                }
                
                owner.viewControllerOption = MenuOptionsViewController()
                owner.viewControllerOption.menuHeight = min((CGFloat)(owner.view.frame.size.height - owner.topicButton.frame.origin.y - owner.topicButton.frame.size.height), (CGFloat)(MenuOptionsViewController.menuItemHeight * (Double)(owner.topicsArray.count)))
                owner.viewControllerOption.menuWidth = owner.topicButton.frame.size.width
                owner.viewControllerOption.delegate​ = owner
                owner.viewControllerOption.options = owner.topicsArray
                owner.viewControllerOption.selectedOptionIndex = owner.selectedTopicIndex
                owner.view.addSubview(owner.viewControllerOption.view)

                owner.viewControllerOption.view.snp_makeConstraints { (make) -> Void in
                    make.trailing.equalTo(owner.topicButton)
                    make.leading.equalTo(owner.topicButton)
                    make.top.equalTo(owner.topicButton.snp_bottom)
                    make.bottom.equalTo(owner.backgroundView.snp_bottom)
                }
                
                owner.viewControllerOption.view.alpha = 0.0
                UIView.animateWithDuration(0.3, animations: {
                        owner.viewControllerOption.view.alpha = 1.0
                    }, completion: nil)
            }
        }, forEvents: UIControlEvents.TouchUpInside)
        
        postDiscussionButton.setTitle(OEXLocalizedString("POST_DISCUSSION", nil), forState: .Normal)

        
        
        tapWrapper = UITapGestureRecognizerWithClosure(view: self.newPostView, tapGestureRecognizer: UITapGestureRecognizer()) {
            self.contentTextView.resignFirstResponder()
            self.titleTextField.resignFirstResponder()
        }

        self.insetsController.setupInController(self, scrollView: scrollView)
    }
    
    private func setSelectedTopicID() {
        var i = 0
        for topic in topics {
            if let name = topic.name, id = topic.id {
                if name == selectedTopic {
                    selectedTopicID = id
                    selectedTopicIndex = i
                    break
                }
            }
            i++
            if topic.children != nil {
                for child in topic.children! {
                    if let name = child.name, id = child.id {
                        if name == selectedTopic {
                            selectedTopicID = id
                            selectedTopicIndex = i
                            return
                        }
                    }
                    i++
                }
            }
        }
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

    func optionSelected(selectedRow: Int, sender: AnyObject) {
        
        selectedTopic = topicsArray[selectedRow].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        // if a topic has at least one child, the topic cannot be selected
        for topic in topics {
            if let name = topic.name {
                if name == selectedTopic {
                    return
                }
            }
        }
        
        topicButton.setTitle(NSString(format: OEXLocalizedString("TOPIC", nil), selectedTopic) as String, forState: .Normal)
        setSelectedTopicID()
        
        UIView.animateWithDuration(0.3, animations: {
            self.viewControllerOption.view.alpha = 0.0
            }, completion: {(finished: Bool) in
                self.viewControllerOption.view.removeFromSuperview()
                self.viewControllerOption = nil
            })
    }
    
}
