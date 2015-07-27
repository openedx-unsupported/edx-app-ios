//
//  DiscussionNewPostViewController.swift
//  edX
//
//  Created by Tang, Jeff on 6/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

struct DiscussionNewThread {
    let courseID: String
    let topicID: String
    let type: String
    let title: String
    let rawBody: String
}

class DiscussionNewPostViewControllerEnvironment: NSObject {
    weak var router: OEXRouter?
    let networkManager : NetworkManager?
    
    init(networkManager : NetworkManager, router: OEXRouter?) {
        self.networkManager = networkManager
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

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsViewControllerDelegate {
    
    private var tapWrapper:UITapGestureRecognizerWithClosure?
    
    private let minBodyTextHeight : CGFloat = 66 // height for 3 lines of text

    private let environment: DiscussionNewPostViewControllerEnvironment
    private let insetsController = ContentInsetsController()
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var backgroundView: UIView!
    
    private var addYourPost: String {
        get {
            return OEXLocalizedString("ADD_YOUR_POST", nil)
        }
    }

    @IBOutlet var newPostView: UIView!
    @IBOutlet var contentTextView: UITextView!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var topicButton: UIButton!
    @IBOutlet var postDiscussionButton: UIButton!
    private let course: OEXCourse
    
    private let topicsArray: [String]

    private let topics: [DiscussionTopic]
    private var selectedTopic: DiscussionTopic?
    
    var viewControllerOption: MenuOptionsViewController!
    
    init(env: DiscussionNewPostViewControllerEnvironment, course: OEXCourse, selectedTopic: DiscussionTopic, topics: [DiscussionTopic], topicsArray: [String]) {

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

        if let topic = selectedTopic, topicID = topic.id, courseID = course.course_id {
            let newThread = DiscussionNewThread(courseID: courseID, topicID: topicID, type: "discussion", title: titleTextField.text, rawBody: contentTextView.text)
            let apiRequest = DiscussionAPI.createNewThread(newThread)
            environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
                self?.navigationController?.popViewControllerAnimated(true)
                self?.postDiscussionButton.enabled = true
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSBundle.mainBundle().loadNibNamed("DiscussionNewPostView", owner: self, options: nil)
        view.addSubview(newPostView)
        newPostView?.autoresizingMask =  UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleLeftMargin
        newPostView?.frame = view.frame
        
        self.navigationItem.title = OEXLocalizedString("POST", nil)
        
        contentTextView.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        contentTextView.layer.masksToBounds = true
        contentTextView.delegate = self
        contentTextView.text = addYourPost
        contentTextView.textColor = OEXStyles.sharedStyles().neutralBase()        
        
        backgroundView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("DISCUSSION", nil), forSegmentAtIndex: 0)
        discussionQuestionSegmentedControl.setTitle(OEXLocalizedString("QUESTION", nil), forSegmentAtIndex: 1)
        
        let styleAttributes = OEXTextStyle(weight: .Normal, size : .Small, color : OEXStyles.sharedStyles().neutralBlack()).attributes
        discussionQuestionSegmentedControl.setTitleTextAttributes(styleAttributes, forState: UIControlState.Selected)
        discussionQuestionSegmentedControl.setTitleTextAttributes(styleAttributes, forState: UIControlState.Normal)
        discussionQuestionSegmentedControl.tintColor = OEXStyles.sharedStyles().neutralLight()
        
        titleTextField.placeholder = OEXLocalizedString("TITLE", nil)
        
        BorderStyle(cornerRadius: OEXStyles.sharedStyles().boxCornerRadius(), width: .Size(1), color: OEXStyles.sharedStyles().neutralXLight()).applyToView(topicButton)
        if let topic = selectedTopic, name = topic.name {
            let title = NSString.oex_stringWithFormat(OEXLocalizedString("TOPIC", nil), parameters: ["topic": name]) as String
            
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(title), forState: .Normal)
        }
        topicButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 0.0)
        
        let dropdownLabel = UILabel()
        let style = OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBase())
        dropdownLabel.attributedText = Icon.Dropdown.attributedTextWithStyle(style.withSize(.XSmall))
        topicButton.addSubview(dropdownLabel)
        dropdownLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(topicButton).offset(-5)
            make.top.equalTo(topicButton).offset(topicButton.frame.size.height / 2.0 - 5.0)
        }
        
        topicButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            if let owner = self {
                if owner.viewControllerOption != nil {
                    return
                }
                
                owner.viewControllerOption = MenuOptionsViewController()
                owner.viewControllerOption.menuHeight = min((CGFloat)(owner.view.frame.height - owner.topicButton.frame.minY - owner.topicButton.frame.height), MenuOptionsViewController.menuItemHeight * (CGFloat)(owner.topicsArray.count))
                owner.viewControllerOption.menuWidth = owner.topicButton.frame.size.width
                owner.viewControllerOption.delegate = owner
                owner.viewControllerOption.options = owner.topicsArray
                owner.viewControllerOption.selectedOptionIndex = owner.selectedTopicIndex()
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
        
        postDiscussionButton.setAttributedTitle(OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralWhite()).attributedStringWithText(OEXLocalizedString("ADD_POST", nil)), forState: .Normal)
        postDiscussionButton.backgroundColor = OEXStyles.sharedStyles().primaryBaseColor()
        postDiscussionButton.layer.cornerRadius = OEXStyles.sharedStyles().boxCornerRadius()
        postDiscussionButton.layer.masksToBounds = true
        
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.resignFirstResponder()
            self?.titleTextField.resignFirstResponder()
        }
        self.newPostView.addGestureRecognizer(tapGesture)

        self.insetsController.setupInController(self, scrollView: scrollView)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == addYourPost {
            textView.text = ""
            textView.textColor = OEXStyles.sharedStyles().neutralBlack()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = addYourPost
            textView.textColor = OEXStyles.sharedStyles().neutralLight()
        }
    }
    
    private func selectedTopicIndex() -> Int? {
        if let topicSelected = selectedTopic {
            var i = 0
            for topic in topics {
                if topicSelected.id == topic.id {
                    return i
                }
                i++
                if let children = topic.children {
                    for child in children {
                        if child.id == topicSelected.id {
                            return i
                        }
                        i++
                    }
                }
            }
        }
        return nil
    }
    
    func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    func textViewDidChange(textView: UITextView) {
        let fixedWidth = textView.frame.size.width
        let newSize = textView.sizeThatFits(CGSizeMake(fixedWidth, CGFloat.max))
        if newSize.height >= minBodyTextHeight {
            bodyTextViewHeightConstraint.constant = newSize.height
        }
    }

    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex: Int) {
        
        selectedTopic = DiscussionTopicsViewController.topicForRow(selectedOptionAtIndex, allTopics: self.topics)
        
        // if a topic has at least one child, the topic cannot be selected (its topic id is nil)
        if let topic = selectedTopic, topicID = topic.id, name = topic.name {
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedString("TOPIC", nil), parameters: ["topic": name]) as String), forState: .Normal)
            
            UIView.animateWithDuration(0.3, animations: {
                self.viewControllerOption.view.alpha = 0.0
                }, completion: {(finished: Bool) in
                    self.viewControllerOption.view.removeFromSuperview()
                    self.viewControllerOption = nil
            })
        }
    }
    
}
