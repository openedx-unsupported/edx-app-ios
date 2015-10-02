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
    let type: PostThreadType
    let title: String
    let rawBody: String
}

public class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsViewControllerDelegate {
 
    public enum OwnerState {
        case AllPosts
        case PostsImFollowing
        case TopLevelTopic
        case Topic(DiscussionTopic)
        
        var selectedTopic : DiscussionTopic? {
            switch self {
            case .AllPosts: return nil
            case .PostsImFollowing: return nil
            case .TopLevelTopic: return nil
            case let .Topic(topic) : return topic
            }
        }
        
        func topicListFromCourseTopics(var topics : [DiscussionTopic]) -> [DiscussionTopic] {
            let chooseATopicItem = DiscussionTopic(id: nil, name: Strings.chooseATopic, children: [])
            switch self {
            case .AllPosts, .PostsImFollowing, .TopLevelTopic: topics.insert(chooseATopicItem, atIndex: 0)
            case .Topic(_) : ()
            }
            return topics
        }
    }
    
    public class Environment: NSObject {
        private let courseDataManager : CourseDataManager
        private let networkManager : NetworkManager?
        private weak var router: OEXRouter?
        
        public init(courseDataManager : CourseDataManager, networkManager : NetworkManager?, router: OEXRouter?) {
            self.courseDataManager = courseDataManager
            self.networkManager = networkManager
            self.router = router
        }
    }
    
    private let minBodyTextHeight : CGFloat = 66 // height for 3 lines of text

    private let environment: Environment
    
    private let growingTextController = GrowingTextViewController()
    private let insetsController = ContentInsetsController()
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var contentTextView: OEXPlaceholderTextView!
    @IBOutlet private var titleTextField: UITextField!
    @IBOutlet private var discussionQuestionSegmentedControl: UISegmentedControl!
    @IBOutlet private var bodyTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var topicButton: UIButton!
    @IBOutlet private var postButton: SpinnerButton!
    
    private let courseID: String
    
    //Used for topics fetched from the network ONLY (not user facing).
    private let courseTopics = BackedStream<[DiscussionTopic]>()

    private var selectedTopic: DiscussionTopic?
    
    private var optionsViewController: MenuOptionsViewController?
    
    private let ownerState : OwnerState

    private var selectedThreadType: PostThreadType = .Discussion {
        didSet {
            switch selectedThreadType {
            case .Discussion:
                self.contentTextView.placeholder = OEXLocalizedString("COURSE_DASHBOARD_DISCUSSION", nil)
                postButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle,withTitle: OEXLocalizedString("POST_DISCUSSION", nil))
            case .Question:
                self.contentTextView.placeholder = OEXLocalizedString("QUESTION", nil)
                postButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: OEXLocalizedString("POST_QUESTION", nil))
            }
        }
    }
    
    private var topics : [DiscussionTopic] {
        return ownerState.topicListFromCourseTopics(self.courseTopics.value ?? [])
    }
    
    public init(environment: Environment, courseID: String, ownerState : OwnerState) {
        self.environment = environment
        self.courseID = courseID
        self.ownerState = ownerState
        
        super.init(nibName: "DiscussionNewPostViewController", bundle: nil)
        
        let stream = environment.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        courseTopics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        
        self.selectedTopic = ownerState.selectedTopic ?? topics[0]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postButton.enabled = false
        postButton.showProgress = true
        // create new thread (post)

        if let topic = selectedTopic, topicID = topic.id {
            let newThread = DiscussionNewThread(courseID: courseID, topicID: topicID, type: selectedThreadType ?? .Discussion, title: titleTextField.text ?? "", rawBody: contentTextView.text)
            let apiRequest = DiscussionAPI.createNewThread(newThread)
            environment.networkManager?.taskForRequest(apiRequest) {[weak self] result in
                self?.dismissViewControllerAnimated(true, completion: nil)
                self?.postButton.enabled = true
                self?.postButton.showProgress = false
            }
            
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = OEXLocalizedString("POST", nil)
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem
        
        
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        contentTextView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = OEXStyles.sharedStyles().neutralLight()
        contentTextView.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        contentTextView.delegate = self
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        let segmentOptions : [(title : String, value : PostThreadType)] = [
            (title : OEXLocalizedString("DISCUSSION", nil), value : .Discussion),
            (title : OEXLocalizedString("QUESTION", nil), value : .Question),
        ]
        let options = segmentOptions.withItemIndexes()
        
        for option in options {
            discussionQuestionSegmentedControl.setTitle(option.value.title, forSegmentAtIndex: option.index)
        }
        
        discussionQuestionSegmentedControl.oex_addAction({ [weak self] (control:AnyObject) -> Void in
            if let segmentedControl = control as? UISegmentedControl {
                let index = segmentedControl.selectedSegmentIndex
                let threadType = segmentOptions[index].value
                self?.selectedThreadType = threadType
            }
            else {
                assert(true, "Invalid Segment ID, Remove this segment index OR handle it in the ThreadType enum")
            }
        }, forEvents: UIControlEvents.ValueChanged)
        
        titleTextField.placeholder = OEXLocalizedString("TITLE", nil)
        titleTextField.defaultTextAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        
        if let topic = selectedTopic, name = topic.name {
            let title = NSString.oex_stringWithFormat(OEXLocalizedString("TOPIC", nil), parameters: ["topic": name]) as String
            
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(title), forState: .Normal)
        }
        
        let insets = OEXStyles.sharedStyles().standardTextViewInsets
        topicButton.titleEdgeInsets = UIEdgeInsetsMake(0, insets.left, 0, insets.right)
        
        topicButton.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        topicButton.contentHorizontalAlignment = topicButton.naturalHorizontalAlignment
        
        let dropdownLabel = UILabel()
        let style = OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
        dropdownLabel.attributedText = Icon.Dropdown.attributedTextWithStyle(style)
        topicButton.addSubview(dropdownLabel)
        dropdownLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(topicButton).offset(-insets.right)
            make.top.equalTo(topicButton).offset(topicButton.frame.size.height / 2.0 - 5.0)
        }
        
        topicButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            self?.showTopicPicker()
        }, forEvents: UIControlEvents.TouchUpInside)
        
        postButton.enabled = false
        
        titleTextField.oex_addAction({[weak self] _ in
            self?.validatePostButton()
            }, forEvents: .EditingChanged)
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.contentTextView.resignFirstResponder()
            self?.titleTextField.resignFirstResponder()
        }
        self.backgroundView.addGestureRecognizer(tapGesture)

        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: postButton)
        self.insetsController.setupInController(self, scrollView: scrollView)
        
        // Force setting it to call didSet which is only called out of initialization context
        self.selectedThreadType = .Discussion
    }
    
    func showTopicPicker() {
        if self.optionsViewController != nil {
            return
        }
        
        self.optionsViewController = MenuOptionsViewController()
        self.optionsViewController?.menuHeight = min((CGFloat)(self.view.frame.height - self.topicButton.frame.minY - self.topicButton.frame.height), MenuOptionsViewController.menuItemHeight * (CGFloat)(topics.count))
        self.optionsViewController?.menuWidth = self.topicButton.frame.size.width
        self.optionsViewController?.delegate = self
        self.optionsViewController?.options = topics.map {
            
            return MenuOptionsViewController.MenuOption(depth : $0.depth, label : $0.name ?? "")
        }
        
        self.optionsViewController?.selectedOptionIndex = self.selectedTopicIndex()
        self.view.addSubview(self.optionsViewController!.view)
        
        self.optionsViewController!.view.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.topicButton)
            make.leading.equalTo(self.topicButton)
            make.top.equalTo(self.topicButton.snp_bottom).offset(-3)
            make.bottom.equalTo(self.view.snp_bottom)
        }
        
        self.optionsViewController?.view.alpha = 0.0
        UIView.animateWithDuration(0.3) {
            self.optionsViewController?.view.alpha = 1.0
        }
    }
    
    private func selectedTopicIndex() -> Int? {
        guard let selected = selectedTopic else {
            return 0
        }
        return self.topics.firstIndexMatching {
                return $0.id == selected.id
        }
    }
    
    public func viewTapped(sender: UITapGestureRecognizer) {
        contentTextView.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
    
    public func textViewDidChange(textView: UITextView) {
        validatePostButton()
        growingTextController.handleTextChange()
    }
    
    public func menuOptionsController(controller : MenuOptionsViewController, canSelectOptionAtIndex index : Int) -> Bool {
        return self.topics[index].id != nil
    }
    
    private func validatePostButton() {
        self.postButton.enabled = !(titleTextField.text ?? "").isEmpty && !contentTextView.text.isEmpty
    }

    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex index: Int) {
        selectedTopic = self.topics[index]
        
        if let topic = selectedTopic, name = topic.name where topic.id != nil {
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(NSString.oex_stringWithFormat(OEXLocalizedString("TOPIC", nil), parameters: ["topic": name]) as String), forState: .Normal)
            
            UIView.animateWithDuration(0.3, animations: {
                self.optionsViewController?.view.alpha = 0.0
                }, completion: {(finished: Bool) in
                    self.optionsViewController?.view.removeFromSuperview()
                    self.optionsViewController = nil
            })
        }
    }
    
    public override func viewDidLayoutSubviews() {
        self.insetsController.updateInsets()
        growingTextController.scrollToVisible()
    }
    
}
