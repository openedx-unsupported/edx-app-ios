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
 
    public typealias Environment = DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXAnalyticsProvider
    
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
    fileprivate let topics = BackedStream<[DiscussionTopic]>()
    private var selectedTopic: DiscussionTopic?
    private var optionsViewController: MenuOptionsViewController?
    weak var delegate: DiscussionNewPostViewControllerDelegate?
    private let tapButton = UIButton()
    
    var titleTextStyle: OEXTextStyle {
        return OEXTextStyle(weight : .normal, size: .small, color: OEXStyles.shared().neutralDark())
    }
    
    private var selectedThreadType: DiscussionThreadType = .Discussion {
        didSet {
            switch selectedThreadType {
            case .Discussion:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [titleTextStyle.attributedString(withText: Strings.Dashboard.courseDiscussion), titleTextStyle.attributedString(withText: Strings.asteric)])
                postButton.applyButtonStyle(style: OEXStyles.shared().filledPrimaryButtonStyle,withTitle: Strings.postDiscussion)
                contentTextView.accessibilityLabel = Strings.Dashboard.courseDiscussion
            case .Question:
                self.contentTitleLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [titleTextStyle.attributedString(withText: Strings.question), titleTextStyle.attributedString(withText: Strings.asteric)])
                postButton.applyButtonStyle(style: OEXStyles.shared().filledPrimaryButtonStyle, withTitle: Strings.postQuestion)
                contentTextView.accessibilityLabel = Strings.question
            }
        }
    }
    
    public init(environment: Environment, courseID: String, selectedTopic : DiscussionTopic?) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: "DiscussionNewPostViewController", bundle: nil)
        
        let stream = environment.dataManager.courseDataManager.discussionManagerForCourseWithID(courseID: courseID).topics
        topics.backWithStream(stream.map {
            return DiscussionTopic.linearizeTopics(topics: $0)
            }
        )
        
        self.selectedTopic = selectedTopic
    }
    
    private var firstSelectableTopic : DiscussionTopic? {
        
        let selectablePredicate = { (topic : DiscussionTopic) -> Bool in
            topic.isSelectable
        }
        
        guard let topics = self.topics.value, let selectableTopicIndex = topics.firstIndexMatching(selectablePredicate) else {
            return nil
        }
        return topics[selectableTopicIndex]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func postTapped(sender: AnyObject) {
        postButton.isEnabled = false
        postButton.showProgress = true
        // create new thread (post)

        if let topic = selectedTopic, let topicID = topic.id {
            let newThread = DiscussionNewThread(courseID: courseID, topicID: topicID, type: selectedThreadType , title: titleTextField.text ?? "", rawBody: contentTextView.text)
            let apiRequest = DiscussionAPI.createNewThread(newThread: newThread)
            environment.networkManager.taskForRequest(apiRequest) {[weak self] result in
                self?.postButton.isEnabled = true
                self?.postButton.showProgress = false
                
                if let post = result.data {
                    self?.delegate?.newPostController(controller: self!, addedPost: post)
                    self?.dismiss(animated: true, completion: nil)
                }
                else {
                    DiscussionHelper.showErrorMessage(controller: self, error: result.error)
                }
            }
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = Strings.post
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelItem.oex_setAction { [weak self]() -> Void in
            self?.dismiss(animated: true, completion: nil)
        }
        self.navigationItem.leftBarButtonItem = cancelItem
        contentTitleLabel.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        titleLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [titleTextStyle.attributedString(withText: Strings.title), titleTextStyle.attributedString(withText: Strings.asteric)])
        contentTextView.textContainer.lineFragmentPadding = 0
        contentTextView.applyStandardBorderStyle()
        contentTextView.delegate = self
        titleTextField.accessibilityLabel = Strings.title
        
        self.view.backgroundColor = OEXStyles.shared().neutralXXLight()
        
        configureSegmentControl()
        titleTextField.defaultTextAttributes = OEXStyles.shared().textAreaBodyStyle.attributes
        setTopicsButtonTitle()
        let insets = OEXStyles.shared().standardTextViewInsets
        topicButton.titleEdgeInsets = UIEdgeInsetsMake(0, insets.left, 0, insets.right)
        topicButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
        
        topicButton.applyBorderStyle(style: OEXStyles.shared().entryFieldBorderStyle)
        topicButton.localizedHorizontalContentAlignment = .Leading
        
        let dropdownLabel = UILabel()
        dropdownLabel.attributedText = Icon.Dropdown.attributedTextWithStyle(style: titleTextStyle)
        topicButton.addSubview(dropdownLabel)
        dropdownLabel.snp.makeConstraints { make in
            make.trailing.equalTo(topicButton).offset(-insets.right)
            make.top.equalTo(topicButton).offset(topicButton.frame.size.height / 2.0 - 5.0)
        }
        
        topicButton.oex_addAction({ [weak self] (action : AnyObject!) -> Void in
            self?.showTopicPicker()
            }, for: UIControlEvents.touchUpInside)
        
        postButton.isEnabled = false
        
        titleTextField.oex_addAction({[weak self] _ in
            self?.validatePostButton()
            }, for: .editingChanged)

        self.growingTextController.setupWithScrollView(scrollView: scrollView, textView: contentTextView, bottomView: postButton)
        self.insetsController.setupInController(owner: self, scrollView: scrollView)
        
        // Force setting it to call didSet which is only called out of initialization context
        self.selectedThreadType = .Question
        
        loadController.setupInController(controller: self, contentView: self.scrollView)
        
        topics.listen(self, success : {[weak self]_ in
            self?.loadedData()
            }, failure : {[weak self] error in
                self?.loadController.state = LoadState.failed(error: error)
            })
        
        backgroundView.addSubview(tapButton)
        backgroundView.sendSubview(toBack: tapButton)
        tapButton.backgroundColor = UIColor.clear
        tapButton.frame = CGRect(x: 0, y: 0, width: backgroundView.frame.size.width, height: backgroundView.frame.size.height)
        tapButton.isAccessibilityElement = false
        tapButton.accessibilityLabel = Strings.accessibilityHideKeyboard
        tapButton.oex_addAction({[weak self] (sender) in
            self?.view.endEditing(true)
            }, for: .touchUpInside)
    }
    
    private func configureSegmentControl() {
        discussionQuestionSegmentedControl.removeAllSegments()
        let questionIcon = Icon.Question.attributedTextWithStyle(style: titleTextStyle)
        let questionTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: [questionIcon,
            titleTextStyle.attributedString(withText: Strings.question)])
        
        let discussionIcon = Icon.Comments.attributedTextWithStyle(style: titleTextStyle)
        let discussionTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: [discussionIcon,
            titleTextStyle.attributedString(withText: Strings.discussion)])
        
        let segmentOptions : [(title : NSAttributedString, value : DiscussionThreadType)] = [
            (title : questionTitle, value : .Question),
            (title : discussionTitle, value : .Discussion),
            ]
        
        for i in 0..<segmentOptions.count {
            discussionQuestionSegmentedControl.insertSegmentWithAttributedTitle(title: segmentOptions[i].title, index: i, animated: false)
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
            }, for: UIControlEvents.valueChanged)
        discussionQuestionSegmentedControl.tintColor = OEXStyles.shared().neutralDark()
        discussionQuestionSegmentedControl.setTitleTextAttributes([NSForegroundColorAttributeName: OEXStyles.shared().neutralWhite()], for: UIControlState.selected)
        discussionQuestionSegmentedControl.selectedSegmentIndex = 0
        
        updateSelectedTabColor()
    }
    
    private func updateSelectedTabColor() {
        // //UIsegmentControl don't Multiple tint color so updating tint color of subviews to match desired behaviour
        let subViews:NSArray = discussionQuestionSegmentedControl.subviews as NSArray
        for i in 0..<subViews.count {
            if (subViews.object(at: i) as AnyObject).isSelected ?? false {
                let view = subViews.object(at: i) as! UIView
                view.tintColor = OEXStyles.shared().primaryBaseColor()
            }
            else {
                let view = subViews.object(at: i) as! UIView
                view.tintColor = OEXStyles.shared().neutralDark()
            }
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.environment.analytics.trackDiscussionScreen(withName: AnalyticsScreenName.CreateTopicThread, courseId: self.courseID, value: selectedTopic?.name, threadId: nil, topicId: selectedTopic?.id, responseID: nil)
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func loadedData() {
        loadController.state = topics.value?.count == 0 ? LoadState.empty(icon: .NoTopics, message : Strings.unableToLoadCourseContent) : .Loaded
        
        if selectedTopic == nil {
            selectedTopic = firstSelectableTopic
        }
        
        setTopicsButtonTitle()
    }
    
    private func setTopicsButtonTitle() {
        if let topic = selectedTopic, let name = topic.name {
            let title = Strings.topic(topic: name)
            topicButton.setAttributedTitle(OEXTextStyle(weight : .normal, size: .small, color: OEXStyles.shared().neutralDark()).attributedString(withText: title), for: .normal)
        }
    }
    
    func showTopicPicker() {
        if self.optionsViewController != nil {
            return
        }
        
        view.endEditing(true)
        
        self.optionsViewController = MenuOptionsViewController()
        self.optionsViewController?.delegate = self
        
        guard let courseTopics = topics.value else {
            //Don't need to configure an empty state here because it's handled in viewDidLoad()
            return
        }
        
        self.optionsViewController?.options = courseTopics.map {
            return MenuOptionsViewController.MenuOption(depth : $0.depth, label : $0.name ?? "")
        }
        
        self.optionsViewController?.selectedOptionIndex = self.selectedTopicIndex()
        self.view.addSubview(self.optionsViewController!.view)
        
        self.optionsViewController!.view.snp.makeConstraints { make in
            make.trailing.equalTo(self.topicButton)
            make.leading.equalTo(self.topicButton)
            make.top.equalTo(self.topicButton.snp.bottom).offset(-3)
            make.bottom.equalTo(safeBottom)
        }
        
        self.optionsViewController?.view.alpha = 0.0
        UIView.animate(withDuration: 0.3) {
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
    
    public func textViewDidChange(_ textView: UITextView) {
        validatePostButton()
        growingTextController.handleTextChange()
    }
    
    public func menuOptionsController(controller : MenuOptionsViewController, canSelectOptionAtIndex index : Int) -> Bool {
        return self.topics.value?[index].isSelectable ?? false
    }
    
    private func validatePostButton() {
        self.postButton.isEnabled = !(titleTextField.text ?? "").isEmpty && !contentTextView.text.isEmpty && self.selectedTopic != nil
    }

    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex index: Int) {
        selectedTopic = self.topics.value?[index]
        
        if let topic = selectedTopic, topic.id != nil {
            setTopicsButtonTitle()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, titleTextField);
            UIView.animate(withDuration: 0.3, animations: {
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
    
    private func textFieldDidBeginEditing(textField: UITextField) {
        tapButton.isAccessibilityElement = true
    }
    
    private func textFieldDidEndEditing(textField: UITextField) {
        tapButton.isAccessibilityElement = false
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        tapButton.isAccessibilityElement = true
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        tapButton.isAccessibilityElement = false
    }
}

extension UISegmentedControl {
    //UIsegmentControl didn't support attributedTitle by default
    func insertSegmentWithAttributedTitle(title: NSAttributedString, index: NSInteger, animated: Bool) {
        let segmentLabel = UILabel()
        segmentLabel.backgroundColor = UIColor.clear
        segmentLabel.textAlignment = .center
        segmentLabel.attributedText = title
        segmentLabel.sizeToFit()
        self.insertSegment(with: segmentLabel.toImage(), at: 1, animated: false)
    }
}

extension UILabel {
    func toImage()-> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext();
        return image;
    }
}

// For use in testing only
extension DiscussionNewPostViewController {
    public func t_topicsLoaded() -> OEXStream<[DiscussionTopic]> {
        return topics
    }
}
