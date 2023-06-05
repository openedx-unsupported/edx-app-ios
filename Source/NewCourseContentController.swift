//
//  NewCourseContentController.swift
//  edX
//
//  Created by MuhammadUmer on 10/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class NewCourseContentController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXRouterProvider & OEXConfigProvider & OEXStylesProvider
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "NewCourseContentController:container-view"
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "NewCourseContentController:contentView-view"
        return view
    }()
    
    private lazy var headerView: CourseContentHeaderView = {
        let headerView = CourseContentHeaderView(environment: environment)
        headerView.accessibilityIdentifier = "NewCourseContentController:header-view"
        headerView.delegate = self
        return headerView
    }()
    
    private lazy var progressStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 1
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.backgroundColor = .clear
        stackView.accessibilityIdentifier = "NewCourseContentController:stack-view"
        return stackView
    }()
    
    private var courseContentViewController: CourseContentPageViewController?
    private var headerViewState: HeaderViewState = .expanded
    
    private var currentBlock: CourseBlock? {
        willSet {
            currentBlock?.completion.unsubscribe(observer: self)
        }
        
        didSet {
            updateView()
            
            currentBlock?.completion.subscribe(observer: self) { [weak self] _,_ in
                self?.updateView()
            }
        }
    }
    
    private let environment: Environment
    private let blockID: CourseBlockID?
    private let parentID: CourseBlockID?
    private let courseID: CourseBlockID
    private let courseQuerier: CourseOutlineQuerier
    
    init(environment: Environment, blockID: CourseBlockID?, resumeCourseBlockID: CourseBlockID? = nil, parentID: CourseBlockID? = nil, courseID: CourseBlockID) {
        self.environment = environment
        self.blockID = blockID
        self.parentID = parentID
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        super.init(nibName: nil, bundle: nil)
        
        if let resumeCourseBlockID = resumeCourseBlockID {
            self.currentBlock = courseQuerier.blockWithID(id: resumeCourseBlockID).firstSuccess().value
        } else {
            findCourseBlockToShow()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubViews()
        setupComponentView()
        setupCompletedBlocksView()
        setStatusBar(color: environment.styles.primaryLightColor())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func addSubViews() {
        view.accessibilityIdentifier = "NewCourseContentController:view"
        view.backgroundColor = .white
        view.addSubview(contentView)
        
        contentView.addSubview(headerView)
        contentView.addSubview(progressStackView)
        contentView.addSubview(containerView)
        
        contentView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 17).priority(.high)
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 17)
        }
        
        progressStackView.snp.remakeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 0.75)
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(progressStackView.snp.bottom)
            make.bottom.equalTo(contentView)
        }
    }
    
    private func setupComponentView() {
        guard let currentBlock = currentBlock,
              let parent = courseQuerier.parentOfBlockWith(id: currentBlock.blockID).firstSuccess().value
        else { return }
        
        let courseContentViewController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: parent.blockID, initialChildID: currentBlock.blockID, forMode: .full)
        courseContentViewController.navigationDelegate = self
        
        let childViewController = ForwardingNavigationController(rootViewController: courseContentViewController)
        courseContentViewController.navigationController?.setNavigationBarHidden(true, animated: false)
        
        containerView.addSubview(childViewController.view)
        
        childViewController.view.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
        }
        
        addChild(childViewController)
        childViewController.didMove(toParent: self)
        
        self.courseContentViewController = courseContentViewController
    }
    
    private func setupCompletedBlocksView() {
        guard let block = currentBlock,
              let section = courseQuerier.parentOfBlockWith(id: block.blockID, type: .Section).firstSuccess().value
        else { return }
        
        let childBlocks = section.children
            .compactMap { courseQuerier.blockWithID(id: $0).firstSuccess().value }
            .flatMap { $0.children }
            .compactMap { courseQuerier.blockWithID(id: $0).firstSuccess().value }
        
        let childViews = childBlocks.map { block in
            let view = UIView()
            view.backgroundColor = block.isCompleted ? environment.styles.accentBColor() : environment.styles.neutralDark()
            return view
        }
        
        headerView.setBlocks(currentBlock: block, blocks: childBlocks)
        progressStackView.removeAllArrangedSubviews()
        progressStackView.addArrangedSubviews(childViews)
    }
    
    private func findCourseBlockToShow() {
        guard let childBlocks = courseQuerier.childrenOfBlockWithID(blockID: blockID, forMode: .full)
            .firstSuccess().value?.children.compactMap({ $0 }).filter({ $0.type == .Unit })
        else { return }
        
        guard let firstInCompleteBlock = childBlocks.flatMap({ $0.children })
            .compactMap({ courseQuerier.blockWithID(id: $0).value })
            .first(where: { !$0.isCompleted })
        else {
            currentBlock = courseQuerier.childrenOfBlockWithID(blockID: childBlocks.first?.blockID, forMode: .full).firstSuccess().value?.children.first
            return
        }
        
        currentBlock = firstInCompleteBlock
    }
    
    private func updateView() {
        guard let block = currentBlock else { return }
        updateTitle(block: block)
        setupCompletedBlocksView()
    }
    
    private func updateTitle(block: CourseBlock) {
        guard let parent = courseQuerier.parentOfBlockWith(id: block.blockID, type: .Section).firstSuccess().value
        else { return }
        headerView.update(title: parent.displayName, subtitle: block.displayName)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        setStatusBar(color: environment.styles.primaryLightColor())
    }
}

extension NewCourseContentController: CourseContentPageViewControllerDelegate {
    func courseContentPageViewController(controller: CourseContentPageViewController, enteredBlockWithID blockID: CourseBlockID, parentID: CourseBlockID) {
        guard let block = courseQuerier.blockWithID(id: blockID).firstSuccess().value else { return }
        currentBlock = block
        if var controller = controller.viewControllers?.first as? ScrollableDelegateProvider {
            controller.scrollableDelegate = self
        }
    }
}

extension NewCourseContentController: CourseContentHeaderViewDelegate {
    func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    func didTapOnUnitBlock(block: CourseBlock) {
        courseContentViewController?.moveToBlock(block: block)
    }
}

extension NewCourseContentController: ScrollableDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard headerViewState != .animating else { return }
        
        if scrollView.contentOffset.y <= 0 {
            if headerViewState == .collapsed {
                headerViewState = .animating
                expandHeaderView()
            }
        } else if headerViewState == .expanded {
            headerViewState = .animating
            collapseHeaderView()
        }
    }
}

extension NewCourseContentController {
    private func expandHeaderView() {
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 17).priority(.high)
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 17)
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.headerView.showHeaderLabel(show: false)
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.headerViewState = .expanded
        }
    }
    
    private func collapseHeaderView() {
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 8)
        }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.headerView.showHeaderLabel(show: true)
            self?.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.headerViewState = .collapsed
        }
    }
}

fileprivate extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
