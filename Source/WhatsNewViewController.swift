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
    
    private var headerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    private var closeTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    private var doneButtonStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralWhite())
    }
    
    typealias Environment = OEXStylesProvider & OEXInterfaceProvider
    private let environment : Environment
    private let dataModel: WhatsNewDataModel
    private var titleString: String
    
    init(environment: Environment, dataModel: WhatsNewDataModel? = nil, title: String? = nil) {
        self.environment = environment
        if let dataModel = dataModel {
            self.dataModel = dataModel
        }
        else {
            self.dataModel = WhatsNewDataModel(environment: environment as? RouterEnvironment)
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
        let appVersion = Bundle.main.oex_shortVersionString()
        let savedAppVersion = environment?.interface?.getSavedAppVersionForWhatsNew()
        let versionDiff = (Float(appVersion) ?? 0.0) - (Float(savedAppVersion ?? "") ?? 0.0)
        return (versionDiff > 0 && environment?.config.isWhatsNewEnabled ?? false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePageViewController()
        configureViews()
        setConstraints()
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
        doneButton.isHidden = true
        headerLabel.accessibilityLabel = Strings.Accessibility.Whatsnew.headerLabel(appVersion: Bundle.main.oex_buildVersionString())
        closeButton.accessibilityLabel = Strings.Accessibility.Whatsnew.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        
        view.addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(doneButton)
        
        headerLabel.attributedText = headerStyle.attributedString(withText: titleString)
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: [
            Icon.Close.attributedTextWithStyle(style: closeTextStyle)])
        closeButton.setAttributedTitle(buttonTitle, for: .normal)
        
        closeButton.oex_addAction({[weak self] _ in
            self?.dismiss(animated: true, completion: nil)
            }, for: .touchUpInside)
        
        doneButton.oex_addAction({ [weak self] _ in
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
    
    private func contentController(withItem item: WhatsNew?)-> UIViewController {
        // UIPageController DataSource methods calling is different in voice over and in normal flow. 
        // In VO UIPageController didn't required viewControllerAfter but it does in normal flow.
        // TODO: revisit this functionality when UIPageController behaves same in all cases.
        UIAccessibilityIsVoiceOverRunning() ? (doneButton.isHidden = !(item?.isLast ?? false)) : (doneButton.isHidden = true)
        let controller = WhatsNewContentController(environment: environment)
        controller.whatsNew = item
        return controller
    }
    
    private func initialItem()-> UIViewController {
        return contentController(withItem: dataModel.fields?.first)
    }
    
    //MARK:- UIPageViewControllerDelegate & UIPageViewControllerDataSource methods
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? WhatsNewContentController {
            if let item = dataModel.prevItem(currentItem: controller.whatsNew) {
                return contentController(withItem: item)
            }
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let controller = viewController as? WhatsNewContentController {
            if let item = dataModel.nextItem(currentItem: controller.whatsNew) {
                return contentController(withItem: item)
            }
        }
        
        doneButton.isHidden = false
        return nil
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return dataModel.fields?.count ?? 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
