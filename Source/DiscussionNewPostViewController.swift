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

class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsViewControllerDelegate {
    class Environment: NSObject {
        private let courseDataManager : CourseDataManager
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        
        init(courseDataManager : CourseDataManager, networkManager : NetworkManager, router: OEXRouter?) {
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
        }
    }
    
    private let minBodyTextHeight : CGFloat = 66 // height for 3 lines of text

    private let environment: Environment
    private let insetsController = ContentInsetsController()
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var backgroundView: UIView!
    
    private var addYourPost: String {
        get {
            return OEXLocalizedString("ADD_YOUR_POST", nil)
        }
    }

    @IBOutlet private var newPostView: UIView!
    @IBOutlet private var contentTextView: UITextView!
    @IBOutlet private var titleTextField: UITextField!
    @IBOutlet private var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet private var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var topicButton: UIButton!
    @IBOutlet private var postDiscussionButton: UIButton!
    
    private let courseID: String
    
    private let topics = BackedStream<[DiscussionTopic]>()

    private var selectedTopic: DiscussionTopic?
    
    var viewControllerOption: MenuOptionsViewController?
    
    init(environment: Environment, courseID: String, selectedTopic: DiscussionTopic) {
        self.environment = environment
        self.courseID = courseID
        self.selectedTopic = selectedTopic
        super.init(nibName: nil, bundle: nil)
        
        let stream = environment.courseDataManager.discussionTopicManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postDiscussionButton.enabled = false
        // create new thread (post)

        if let topic = selectedTopic, topicID = topic.id {
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
            self?.showTopicPicker()
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
    
    func showTopicPicker() {
        if self.viewControllerOption != nil {
            return
        }
        let topics = self.topics.value ?? []
        
        self.viewControllerOption = MenuOptionsViewController()
        self.viewControllerOption?.menuHeight = min((CGFloat)(self.view.frame.height - self.topicButton.frame.minY - self.topicButton.frame.height), MenuOptionsViewController.menuItemHeight * (CGFloat)(topics.count))
        self.viewControllerOption?.menuWidth = self.topicButton.frame.size.width
        self.viewControllerOption?.delegate = self
        self.viewControllerOption?.options = topics.map {
            return $0.name ?? ""
        }
        self.viewControllerOption?.selectedOptionIndex = self.selectedTopicIndex()
        self.view.addSubview(self.viewControllerOption!.view)
        
        self.viewControllerOption!.view.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.topicButton)
            make.leading.equalTo(self.topicButton)
            make.top.equalTo(self.topicButton.snp_bottom)
            make.bottom.equalTo(self.backgroundView.snp_bottom)
        }
        
        self.viewControllerOption?.view.alpha = 0.0
        UIView.animateWithDuration(0.3) {
            self.viewControllerOption?.view.alpha = 1.0
        }
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
        return self.topics.value?.firstIndexMatching {
            return $0.id == selectedTopic?.id
        }
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
    
    func menuOptionsController(controller : MenuOptionsViewController, canSelectOptionAtIndex index : Int) -> Bool {
        if let topic = self.topics.value?[index] {
            return topic.id != nil
        }
        else {
            return false
        }
    }

    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex index: Int) {
        selectedTopic = self.topics.value?[index]
        
        // if a topic has at least one child, the topic cannot be selected (its topic id is nil)
        if let topic = selectedTopic, name = topic.name where topic.id != nil {
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedString("TOPIC", nil), parameters: ["topic": name]) as String), forState: .Normal)
            
            UIView.animateWithDuration(0.3, animations: {
                self.viewControllerOption?.view.alpha = 0.0
                }, completion: {(finished: Bool) in
                    self.viewControllerOption?.view.removeFromSuperview()
                    self.viewControllerOption = nil
            })
        }
    }
    
}
