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
    let type: DiscussionThreadType
    let title: String
    let rawBody: String
}

protocol DiscussionNewPostViewControllerDelegate : class {
    func newPostController(controller  : DiscussionNewPostViewController, addedPost post: DiscussionThread)
}

public class DiscussionNewPostViewController: UIViewController, UITextViewDelegate, MenuOptionsViewControllerDelegate, InterfaceOrientationOverriding {
 
    public typealias Environment = protocol<DataManagerProvider, NetworkManagerProvider, OEXRouterProvider, OEXAnalyticsProvider>
    
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
    @IBOutlet weak var contentTitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    
    private let loadController = LoadStateViewController()
    private let courseID: String
    private let topics = BackedStream<[DiscussionTopic]>()
    private var selectedTopic: DiscussionTopic?
    private var optionsViewController: MenuOptionsViewController?
    weak var delegate: DiscussionNewPostViewControllerDelegate?
    private let tapButton = UIButton()
    
    var titleTextStyle : OEXTextStyle{
        return OEXTextStyle(weight : .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var selectedThreadType: DiscussionThreadType = .Discussion {
        didSet {
            switch selectedThreadType {
            case .Discussion:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedStringWithText(Strings.courseDashboardDiscussion), titleTextStyle.attributedStringWithText(Strings.asteric)])
                postButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle,withTitle: Strings.postDiscussion)
                contentTextView.accessibilityLabel = Strings.courseDashboardDiscussion
            case .Question:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedStringWithText(Strings.question), titleTextStyle.attributedStringWithText(Strings.asteric)])
                postButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.postQuestion)
                contentTextView.accessibilityLabel = Strings.question
            }
        }
    }
    
    public init(environment: Environment, courseID: String, selectedTopic : DiscussionTopic?) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: "DiscussionNewPostViewController", bundle: nil)
        
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics($0)
            }
        )
        
        self.selectedTopic = selectedTopic
    }
    
    private var firstSelectableTopic : DiscussionTopic? {
        
        let selectablePredicate = { (topic : DiscussionTopic) -> Bool in
            topic.isSelectable
        }
        
        guard let topics = self.topics.value, selectableTopicIndex = topics.firstIndexMatching(selectablePredicate) else {
            return nil
        }
        return topics[selectableTopicIndex]
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
            environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                self?.postButton.enabled = true
                self?.postButton.showProgress = false
                
                if let post = result.data {
                    self?.delegate?.newPostController(self!, addedPost: post)
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }
                else {
                 self?.showOverlayMessage(DiscussionHelper.messageForError(result.error))
                }
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = Strings.post
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem
        contentTitleLabel.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        titleLabel.attributedText = NSAttributedString.joinInNaturalLayout([titleTextStyle.attributedStringWithText(Strings.title), titleTextStyle.attributedStringWithText(Strings.asteric)])
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.textContainerInset = OEXStyles.sharedStyles().standardTextViewInsets
        contentTextView.typingAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        contentTextView.placeholderTextColor = OEXStyles.sharedStyles().neutralLight()
        contentTextView.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        contentTextView.delegate = self
        titleTextField.accessibilityLabel = Strings.title
        
        self.view.backgroundColor = OEXStyles.sharedStyles().neutralXXLight()
        
        configureSegmentControl()
        titleTextField.defaultTextAttributes = OEXStyles.sharedStyles().textAreaBodyStyle.attributes
        setTopicsButtonTitle()
        let insets = OEXStyles.sharedStyles().standardTextViewInsets
        topicButton.titleEdgeInsets = UIEdgeInsetsMake(0, insets.left, 0, insets.right)
        topicButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
        
        topicButton.applyBorderStyle(OEXStyles.sharedStyles().entryFieldBorderStyle)
        topicButton.localizedHorizontalContentAlignment = .Leading
        
        let dropdownLabel = UILabel()
        dropdownLabel.attributedText = Icon.Dropdown.attributedTextWithStyle(titleTextStyle)
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

        self.growingTextController.setupWithScrollView(scrollView, textView: contentTextView, bottomView: postButton)
        self.insetsController.setupInController(self, scrollView: scrollView)
        
        // Force setting it to call didSet which is only called out of initialization context
        self.selectedThreadType = .Question
        
        loadController.setupInController(self, contentView: self.scrollView)
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error)
            })
        
        backgroundView.addSubview(tapButton)
        backgroundView.sendSubviewToBack(tapButton)
        tapButton.backgroundColor = UIColor.clearColor()
        tapButton.frame = CGRectMake(0, 0, backgroundView.frame.size.width, backgroundView.frame.size.height)
        tapButton.isAccessibilityElement = false
        tapButton.accessibilityLabel = Strings.accessibilityHideKeyboard
        tapButton.oex_addAction({[weak self] (sender) in
            self?.view.endEditing(true)
            }, forEvents: .TouchUpInside)
    }
    
    private func configureSegmentControl() {
        discussionQuestionSegmentedControl.removeAllSegments()
        let questionIcon = Icon.Question.attributedTextWithStyle(titleTextStyle)
        let questionTitle = NSAttributedString.joinInNaturalLayout([questionIcon,
            titleTextStyle.attributedStringWithText(Strings.question)])
        
        let discussionIcon = Icon.Comments.attributedTextWithStyle(titleTextStyle)
        let discussionTitle = NSAttributedString.joinInNaturalLayout([discussionIcon,
            titleTextStyle.attributedStringWithText(Strings.discussion)])
        
        let segmentOptions : [(title : NSAttributedString, value : DiscussionThreadType)] = [
            (title : questionTitle, value : .Question),
            (title : discussionTitle, value : .Discussion),
            ]
        
        for i in 0..<segmentOptions.count {
            discussionQuestionSegmentedControl.insertSegmentWithAttributedTitle(segmentOptions[i].title, index: i, animated: false)
            discussionQuestionSegmentedControl.subviews[i].accessibilityLabel = segmentOptions[i].title.string
        }
        
        discussionQuestionSegmentedControl.oex_addAction({ [weak self] (control:AnyObject) -> Void in
            if let segmentedControl = control as? UISegmentedControl {
                let index = segmentedControl.selectedSegmentIndex
                let threadType = segmentOptions[index].value
                self?.selectedThreadType = threadType
                self?.updateSelectedTabColor()
            }
            else {
                assert(true, "Invalid Segment ID, Remove this segment index OR handle it in the ThreadType enum")
            }
            }, forEvents: UIControlEvents.ValueChanged)
        discussionQuestionSegmentedControl.tintColor = OEXStyles.sharedStyles().neutralDark()
        discussionQuestionSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: OEXStyles.sharedStyles().neutralWhite()], forState: UIControlState.Selected)
        discussionQuestionSegmentedControl.selectedSegmentIndex = 0
        
        updateSelectedTabColor()
    }
    
    private func updateSelectedTabColor() {
        // //UIsegmentControl don't Multiple tint color so updating tint color of subviews to match desired behaviour
        let subViews:NSArray = discussionQuestionSegmentedControl.subviews
        for i in 0..<subViews.count {
            if subViews.objectAtIndex(i).isSelected ?? false {
                let view = subViews.objectAtIndex(i) as! UIView
                view.tintColor = OEXStyles.sharedStyles().primaryBaseColor()
            }
            else {
                let view = subViews.objectAtIndex(i) as! UIView
                view.tintColor = OEXStyles.sharedStyles().neutralDark()
            }
        }
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.environment.analytics.trackDiscussionScreenWithName(OEXAnalyticsScreenCreateTopicThread, courseId: self.courseID, value: selectedTopic?.name, threadId: nil, topicId: selectedTopic?.id, responseID: nil)
    }
    
    override public func shouldAutorotate() -> Bool {
        return true
    }
    
    override public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .AllButUpsideDown
    }
    
    private func loadedData() {
        loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .NoTopics, message : Strings.unableToLoadCourseContent) : .Loaded
        
        if selectedTopic == nil {
            selectedTopic = firstSelectableTopic
        }
        
        setTopicsButtonTitle()
    }
    
    private func setTopicsButtonTitle() {
        if let topic = selectedTopic, name = topic.name {
            let title = Strings.topic(topic: name)
            topicButton.setAttributedTitle(OEXTextStyle(weight : .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark()).attributedStringWithText(title), forState: .Normal)
        }
    }
    
    func showTopicPicker() {
        if self.optionsViewController != nil {
            return
        }
        
        view.endEditing(true)
        
        self.optionsViewController = MenuOptionsViewController()
        self.optionsViewController?.delegate = self
        
        guard let courseTopics = topics.value else  {
            //Don't need to configure an empty state here because it's handled in viewDidLoad()
            return
        }
        
        self.optionsViewController?.options = courseTopics.map {
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
        return self.topics.value?.firstIndexMatching {
                return $0.id == selected.id
        }
    }
    
    public func textViewDidChange(textView: UITextView) {
        validatePostButton()
        growingTextController.handleTextChange()
    }
    
    public func menuOptionsController(controller : MenuOptionsViewController, canSelectOptionAtIndex index : Int) -> Bool {
        return self.topics.value?[index].isSelectable ?? false
    }
    
    private func validatePostButton() {
        self.postButton.enabled = !(titleTextField.text ?? "").isEmpty && !contentTextView.text.isEmpty && self.selectedTopic != nil
    }

    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex index: Int) {
        selectedTopic = self.topics.value?[index]
        
        if let topic = selectedTopic where topic.id != nil {
            setTopicsButtonTitle()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, titleTextField);
            UIView.animateWithDuration(0.3, animations: {
                self.optionsViewController?.view.alpha = 0.0
                }, completion: {[weak self](finished: Bool) in
                    self?.optionsViewController?.view.removeFromSuperview()
                    self?.optionsViewController = nil
            })
        }
    }
    
    public override func viewDidLayoutSubviews() {
        self.insetsController.updateInsets()
        growingTextController.scrollToVisible()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        tapButton.isAccessibilityElement = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        tapButton.isAccessibilityElement = false
    }
    
    public func textViewDidBeginEditing(textView: UITextView) {
        tapButton.isAccessibilityElement = true
    }
    
    public func textViewDidEndEditing(textView: UITextView) {
        tapButton.isAccessibilityElement = false
    }
}

extension UISegmentedControl {
    //UIsegmentControl didn't support attributedTitle by default
    func insertSegmentWithAttributedTitle(title: NSAttributedString, index: NSInteger, animated: Bool) {
        let segmentLabel = UILabel()
        segmentLabel.backgroundColor = UIColor.clearColor()
        segmentLabel.textAlignment = .Center
        segmentLabel.attributedText = title
        segmentLabel.sizeToFit()
        self.insertSegmentWithImage(segmentLabel.toImage(), atIndex: 1, animated: false)
    }
}

extension UILabel {
    func toImage()-> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        return image;
    }
}

// For use in testing only
extension DiscussionNewPostViewController {
    public func t_topicsLoaded() -> Stream<[DiscussionTopic]> {
        return topics
    }
}
