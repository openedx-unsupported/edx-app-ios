//
//  WhatsNewViewController.swift
//  edX
//
//  Created by Saeed Bashir on 5/2/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

class WhatsNewViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    private let containerView: UIView = UIView()
    private let closeButton = UIButton(type: .system)
    private let headerLabel = UILabel()
    private let pageController: UIPageViewController
    private let doneButton = UIButton(type: .system)
    
    private let closeImageSize: CGFloat = 16
    private let topSpace: CGFloat = 22
    private var pagesViewed: Int = 0 // This varibale will only be used for analytics
    private var currentPageIndex: Int = 0 // This varibale will only be used for analytics
    
    private var headerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    private var closeTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    private var doneButtonStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    typealias Environment = OEXStylesProvider & OEXInterfaceProvider & OEXAnalyticsProvider
    private let environment : Environment
    private let dataModel: WhatsNewDataModel
    private var titleString: String
    
    init(environment: Environment, dataModel: WhatsNewDataModel? = nil, title: String? = nil) {
        self.environment = environment
        if let dataModel = dataModel {
            self.dataModel = dataModel
        }
        else {
            self.dataModel = WhatsNewDataModel(environment: environment as? RouterEnvironment, version: Bundle.main.oex_buildVersionString())
        }
        titleString = title ?? Strings.WhatsNew.headerText(appVersion: Bundle.main.oex_buildVersionString())
        pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        environment.interface?.saveAppVersionOnWhatsNewAppear()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func canShowWhatsNew(environment: RouterEnvironment?) -> Bool {
        let appVersion = Version(version: Bundle.main.oex_buildVersionString())
        let savedAppVersion = Version(version: environment?.interface?.getSavedAppVersionForWhatsNew() ?? "")
        let validDiff = appVersion.isNMinorVersionsDiff(otherVersion: savedAppVersion, minorVersionDiff: 1)
        return (validDiff && environment?.config.isWhatsNewEnabled ?? false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePageViewController()
        configureViews()
        setConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logScreenEvent()
    }
    
    private func configurePageViewController() {
        pageController.setViewControllers([initialItem()], direction: .forward, animated: false, completion: nil)
        pageController.delegate = self
        pageController.dataSource = self
        addChildViewController(pageController)
        containerView.addSubview(pageController.view)
        pageController.didMove(toParentViewController: self)
    }
    
    private func configureViews() {
        view.backgroundColor = environment.styles.primaryBaseColor()
        doneButton.setAttributedTitle(doneButtonStyle.attributedString(withText: Strings.WhatsNew.done), for: .normal)
        headerLabel.accessibilityLabel = Strings.Accessibility.Whatsnew.headerLabel(appVersion: Bundle.main.oex_buildVersionString())
        closeButton.accessibilityLabel = Strings.Accessibility.Whatsnew.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        
        view.addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(doneButton)
        showDoneButtonAtLastScreen()
        
        headerLabel.attributedText = headerStyle.attributedString(withText: titleString)
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: [
            Icon.Close.attributedTextWithStyle(style: closeTextStyle)])
        closeButton.setAttributedTitle(buttonTitle, for: .normal)
        
        closeButton.oex_addAction({[weak self] _ in
            self?.logCloseEvent()
            self?.dismiss(animated: true, completion: nil)
            }, for: .touchUpInside)
        
        doneButton.oex_addAction({ [weak self] _ in
            self?.logDoneEvent()
            self?.dismiss(animated: true, completion: nil)
            }, for: .touchUpInside)
    }
    
    private func setConstraints() {
        containerView.snp_makeConstraints {make in
            make.edges.equalTo(view)
        }
        
        headerLabel.snp_makeConstraints { make in
            make.top.equalTo(containerView).offset(topSpace)
            make.centerX.equalTo(containerView)
        }
        
        closeButton.snp_makeConstraints { make in
            make.top.equalTo(containerView).offset(topSpace)
            make.trailing.equalTo(containerView)
        }
        
        pageController.view.snp_makeConstraints { make in
            make.top.equalTo(headerLabel.snp_bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.leading.equalTo(containerView)
        }
        
        doneButton.snp_makeConstraints { make in
            make.bottom.equalTo(containerView).offset(-StandardVerticalMargin / 2)
            make.trailing.equalTo(containerView).offset(-StandardHorizontalMargin)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle(barStyle : nil)
    }
    
    private func contentController(withItem item: WhatsNew?, direction: UIPageViewControllerNavigationDirection)-> UIViewController {
        // UIPageController DataSource methods calling is different in voice over and in normal flow. 
        // In VO UIPageController didn't required viewControllerAfter but it does in normal flow.
        // TODO: revisit this functionality when UIPageController behaves same in all cases.
        
        switch direction {
        case .forward:
            let totalScreens = dataModel.fields?.count ?? 0
            (pagesViewed >= totalScreens) ? (pagesViewed = totalScreens + 1) : (pagesViewed += 1)
        default:
            break
        }
        
        UIAccessibilityIsVoiceOverRunning() ? (doneButton.isHidden = !(item?.isLast ?? false)) : (doneButton.isHidden = true)
        let controller = WhatsNewContentController(environment: environment)
        controller.whatsNew = item
        return controller
    }
    
    private func initialItem()-> UIViewController {
        return contentController(withItem: dataModel.fields?.first, direction: .forward)
    }
    
    private func showDoneButtonAtLastScreen() {
        let totalScreens = dataModel.fields?.count ?? 0
        doneButton.isHidden = currentPageIndex != totalScreens - 1
    }
    
    //MARK:- Analytics 
    
    private func logScreenEvent() {
        let params = [key_app_version : Bundle.main.oex_buildVersionString()]
        environment.analytics.trackScreen(withName: AnalyticsScreenName.WhatsNew.rawValue, courseID: nil, value: nil, additionalInfo: params)
    }
    
    private func logCloseEvent() {
        (pagesViewed == 1) ? (pagesViewed = pagesViewed) : (pagesViewed -= 1)
        let params = [key_app_version : Bundle.main.oex_buildVersionString(), "total_viewed": pagesViewed, "currently_viewed": currentPageIndex + 1, "total_screens": dataModel.fields?.count ?? 0] as [String : Any]
        environment.analytics.trackEvent(whatsNewEvent(name: AnalyticsEventName.WhatsNewClose.rawValue, displayName: "WhatsNew: Close"), forComponent: nil, withInfo: params)
    }
    
    private func logDoneEvent() {
        let params = [key_app_version : Bundle.main.oex_buildVersionString(), "total_screens": dataModel.fields?.count ?? 0] as [String : Any]
        environment.analytics.trackEvent(whatsNewEvent(name: AnalyticsEventName.WhatsNewDone.rawValue, displayName: "WhatsNew: Done"), forComponent: nil, withInfo: params)
    }
    
    private func whatsNewEvent(name: String, displayName: String) -> OEXAnalyticsEvent {
        let event = OEXAnalyticsEvent()
        event.name = name
        event.displayName = displayName
        event.category = AnalyticsCategory.WhatsNew.rawValue
        return event
    }
    
    //MARK:- UIPageViewControllerDelegate & UIPageViewControllerDataSource methods
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? WhatsNewContentController {
            if let item = dataModel.prevItem(currentItem: controller.whatsNew) {
                return contentController(withItem: item, direction: .reverse)
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? WhatsNewContentController {
            if let item = dataModel.nextItem(currentItem: controller.whatsNew) {
                return contentController(withItem: item, direction: .forward)
            }
        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let controller = pageViewController.viewControllers?.last as? WhatsNewContentController, finished == true {
            currentPageIndex = dataModel.itemIndex(item: controller.whatsNew)
        }
        showDoneButtonAtLastScreen()
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return dataModel.fields?.count ?? 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
