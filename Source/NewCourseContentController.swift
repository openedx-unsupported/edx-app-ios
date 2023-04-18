//
//  NewCourseContentController.swift
//  edX
//
//  Created by MuhammadUmer on 10/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

class NewCourseContentController: UIViewController {
    
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
    
    private lazy var stackView: UIStackView = {
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
    
    init(environment: Environment, blockID: CourseBlockID?, parentID: CourseBlockID?, courseID: CourseBlockID) {
        self.environment = environment
        self.blockID = blockID
        self.parentID = parentID
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        super.init(nibName: nil, bundle: nil)
        findCourseBlockToShow()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        contentView.addSubview(stackView)
        contentView.addSubview(containerView)
        
        contentView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        headerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 14)
        }
        
        stackView.snp.remakeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.height.equalTo(StandardVerticalMargin * 0.75)
        }
        
        containerView.snp.makeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(stackView.snp.bottom)
            make.bottom.equalTo(contentView)
        }
    }
    
    private func setupComponentView() {
        guard let currentBlock = currentBlock,
              let parent = courseQuerier.parentOfBlockWith(id: currentBlock.blockID).firstSuccess().value
        else { return }
        
        let courseContentViewController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: parent.blockID, forMode: .full)
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
              let sectionBlock = courseQuerier.parentOfBlockWith(id: block.blockID, type: .Section).firstSuccess().value
        else { return }
        
        let childViews = sectionBlock.children
            .compactMap { courseQuerier.blockWithID(id: $0).firstSuccess().value }
            .flatMap { $0.children }
            .compactMap { courseQuerier.blockWithID(id: $0).firstSuccess().value }
            .map { childBlock in
                let childView = UIView()
                childView.backgroundColor = childBlock.isCompleted ? environment.styles.accentBColor() : environment.styles.neutralDark()
                return childView
            }
        
        stackView.removeAllArrangedSubviews()
        stackView.addArrangedSubviews(childViews)
    }
    
    private func findCourseBlockToShow() {
        guard let children = courseQuerier.childrenOfBlockWithID(blockID: blockID, forMode: .full)
            .firstSuccess().value?.children.compactMap({ $0 }).filter({ $0.type == .Unit })
        else { return }
        
        guard let firstInCompleteBlock = children.flatMap({ $0.children })
            .compactMap({ courseQuerier.blockWithID(id: $0).value })
            .first(where: { !$0.isCompleted })
        else {
            self.currentBlock = children.first
            return
        }
        
        self.currentBlock = firstInCompleteBlock
    }
    
    private func updateView() {
        guard let block = currentBlock else { return }
        updateTitle(block: block)
        setupCompletedBlocksView()
    }
    
    private func updateTitle(block: CourseBlock) {
        guard let parentBlock = courseQuerier.parentOfBlockWith(id: block.blockID).firstSuccess().value
        else { return }
        headerView.setup(title: parentBlock.displayName, subtitle: block.displayName)
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
    func didTapOnClose() {
        navigationController?.popViewController(animated: true)
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
            make.height.lessThanOrEqualTo(StandardVerticalMargin * 14)
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
            make.height.equalTo(StandardVerticalMargin * 5)
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
