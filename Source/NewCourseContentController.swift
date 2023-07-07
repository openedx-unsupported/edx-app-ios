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
        view.accessibilityIdentifier = "NewCourseContentController:content-view"
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
        stackView.accessibilityIdentifier = "NewCourseContentController:progress-stack-view"
        return stackView
    }()
    
    private var courseContentViewController: CourseContentPageViewController?
    private var headerViewState: HeaderViewState = .expanded
    private var statusBarTag = 999999
    
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
    private let courseOutlineMode: CourseOutlineMode
    
    init(environment: Environment, blockID: CourseBlockID?, resumeCourseBlockID: CourseBlockID? = nil, parentID: CourseBlockID? = nil, courseID: CourseBlockID, courseOutlineMode: CourseOutlineMode? = .full) {
        self.environment = environment
        self.blockID = blockID
        self.parentID = parentID
        self.courseID = courseID
        self.courseOutlineMode = courseOutlineMode ?? .full
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        super.init(nibName: nil, bundle: nil)
        
        if let resumeCourseBlockID = resumeCourseBlockID {
            currentBlock = courseQuerier.blockWithID(id: resumeCourseBlockID).firstSuccess().value
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
        
        setStatusBar(color: environment.styles.primaryLightColor())
        addSubViews()
        setupComponentView()
        setupCompletedBlocksView()
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
        
        let courseContentViewController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: parent.blockID, initialChildID: currentBlock.blockID, forMode: courseOutlineMode)
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
            let section = courseQuerier.parentOfBlockWith(id: block.blockID, type: .Section).firstSuccess().value,
            let sectionChildren = courseQuerier.childrenOfBlockWithID(blockID: section.blockID, forMode: courseOutlineMode).value
        else { return }
        
        let childBlocks: [CourseBlock] = sectionChildren.children.compactMap { item in
            courseQuerier.childrenOfBlockWithID(blockID: item.blockID, forMode: courseOutlineMode)
                .firstSuccess().value?.children ?? []
        }.flatMap { $0 }

        let childViews: [UIView] = childBlocks.map { block -> UIView in
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
        
        let blocks: [CourseBlock] = childBlocks.flatMap { block in
            courseQuerier.childrenOfBlockWithID(blockID: block.blockID, forMode: courseOutlineMode).value?.children.compactMap { child in
                courseQuerier.blockWithID(id: child.blockID).value
            } ?? []
        }

        currentBlock = blocks.first(where: { !$0.isCompleted }) ?? blocks.last
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
        coordinator.animate { [weak self] _ in
            guard let weakSelf = self else { return }
            if weakSelf.currentOrientation() == .portrait {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    weakSelf.setStatusBar(color: weakSelf.environment.styles.primaryLightColor())
                }
            } else {
                weakSelf.removeStatusBar()
            }
        }
        
        if headerViewState == .collapsed {
            collapseHeaderView()
        } else if headerViewState == .expanded {
            expandHeaderView()
        }
    }
}

extension NewCourseContentController: CourseContentPageViewControllerDelegate {
    func courseContentPageViewController(controller: CourseContentPageViewController, enteredBlockWithID blockID: CourseBlockID, parentID: CourseBlockID) {
        guard let block = courseQuerier.blockWithID(id: blockID).firstSuccess().value else { return }
        currentBlock = block
        if var controller = controller.viewControllers?.first as? ScrollableDelegateProvider {
            controller.scrollableDelegate = self
        }
        
        // header animation is overlapping with UIPageController animation which results in crash
        // calling the header animation after a delay of 1 sec to overcome the issue
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.updateHeaderState(with: controller)
        }
    }
    
    private func updateHeaderState(with controller: CourseContentPageViewController) {
        if let controller = controller.viewControllers?.first as? VideoBlockViewController {
            controller.orientationDelegate = self
            
            if currentOrientation() != .portrait {
                collapseHeaderView()
            } else if headerViewState == .collapsed {
                collapseHeaderView()
            } else if headerViewState == .expanded {
                expandHeaderView()
            }
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

extension NewCourseContentController: VideoBlockViewControllerOrientationDelegate {
    func changeOrientation(orientation: UIInterfaceOrientation) {
        if orientation == .portrait {
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

fileprivate extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }
    
    func removeAllArrangedSubviews() {
        arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
}
