//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & OEXAnalyticsProvider & OEXConfigProvider & OEXStylesProvider & OEXRouterProvider & DataManagerProvider & RemoteConfigProvider
    
    private let environment: Environment
        
    let blockID: CourseBlockID?
    let courseID: String
    private var block: CourseBlock? {
        didSet {
            navigationItem.title = block?.displayName
        }
    }
    private var messageView: IconMessageView?
    private lazy var valuePropView: ValuePropMessageView = {
        let view = ValuePropMessageView(environment: environment)
        view.delegate = self
        return view
    }()
    
    private var loader: OEXStream<URL?>?
    
    init(blockID: CourseBlockID?, courseID: String, environment: Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: self.courseID, environment: environment)
        courseQuerier.blockWithID(id: blockID).extendLifetimeUntilFirstResult (
            success: { [weak self] block in
                self?.block = block
                if let video = block.type.asVideo, video.isYoutubeVideo {
                    self?.showYoutubeMessage(buttonTitle: Strings.Video.viewOnYoutube, message: Strings.Video.onlyOnYoutube, icon: Icon.CourseVideos, videoUrl: video.videoURL)
                } else {
                    self?.showError()
                }
            },
            failure: { [weak self] _ in
                self?.showError()
            }
        )
    }
    
    private func showYoutubeMessage(buttonTitle: String, message: String, icon: Icon, videoUrl: String?) {
        messageView = IconMessageView(icon: icon, message: message)
        messageView?.buttonInfo = MessageButtonInfo(title : buttonTitle) {
            guard let videoURL = videoUrl, let url = URL(string: videoURL), UIApplication.shared.canOpenURL(url) else { return }
            UIApplication.shared.openURL(url)
        }
        
        if let messageView = messageView {
            view.addSubview(messageView)
        }
    }
    
    private func showError() {
        if let block = block, block.isGated {
            if environment.remoteConfig.isValuePropEnabled {
                showValuePropMessageView()
            } else {
                showGatedContentMessageView()
            }
        } else {
            showCourseContentUnknownView()
        }
    }
    
    private func showGatedContentMessageView() {
        configureIconMessage(with: IconMessageView(icon: Icon.Closed, message: Strings.courseContentGated))
    }
    
    private func showCourseContentUnknownView() {
        configureIconMessage(with: IconMessageView(icon: Icon.CourseUnknownContent, message: Strings.courseContentUnknown))
    }
    
    private func configureIconMessage(with iconView: IconMessageView) {
        messageView = iconView
        
        messageView?.buttonInfo = MessageButtonInfo(title : Strings.openInBrowser) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loader?.listen(weakSelf, success : { url in
                guard let url = url, UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.openURL(url)
                weakSelf.logOpenInBrowserEvent()
            }, failure : { _ in })
        }
        if let messageView = messageView {
            view.addSubview(messageView)
        }
    }
    
    private func showValuePropMessageView() {
        view.addSubview(valuePropView)
        
        valuePropView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
    }
    
    override func updateViewConstraints() {
        if isVerticallyCompact() {
            applyLandscapeConstraints()
        } else {
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        messageView?.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func applyLandscapeConstraints() {
        messageView?.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(safeBottom).offset(-barHeight)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loader = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment).blockWithID(id: blockID).map { $0.webURL as URL? }.firstSuccess()
    }
    
    private func logOpenInBrowserEvent() {
        guard let block = block else { return }
        
        environment.analytics.trackOpenInBrowser(withURL: block.blockURL?.absoluteString ?? "", courseID: courseID, blockID: block.blockID, minifiedBlockID: block.minifiedBlockID ?? "", supported: block.multiDevice)
    }
}

extension CourseUnknownBlockViewController: ValuePropMessageViewDelegate {
    func showValuePropDetailView() {
        guard let course = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.course else { return }
        environment.analytics.trackValuePropLearnMore(courseID: courseID, screenName: .CourseUnit, assignmentID: blockID)
        environment.router?.showValuePropDetailView(from: self, type: .courseUnit, course: course) { [weak self] in
            if let weakSelf = self {
                weakSelf.environment.analytics.trackValueProModal(with: .ValuePropModalForCourseUnit, courseId: weakSelf.courseID, assignmentID: weakSelf.blockID)
            }
        }
    }
}
