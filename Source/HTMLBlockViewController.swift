//
//  HTMLBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class HTMLBlockViewController: UIViewController, CourseBlockViewController, PreloadableBlockController, DateResetSnackBar {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & OEXSessionProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider
    
    public let courseID: String
    public let blockID: CourseBlockID?
    private let environment: Environment
    private let subkind: CourseHTMLBlockSubkind
    
    private lazy var courseDateBannerView = CourseDateBannerView(frame: .zero)
    private let webController: AuthenticatedWebViewController
    
    private let loader = BackedStream<CourseBlock>()
    private let courseDateBannerLoader = BackedStream<(CourseDateBannerModel)>()
    private let courseQuerier: CourseOutlineQuerier
    
    public init(blockID: CourseBlockID?, courseID: String, environment: Environment, subkind: CourseHTMLBlockSubkind) {
        self.courseID = courseID
        self.blockID = blockID
        self.subkind = subkind
        self.environment = environment
        
        webController = AuthenticatedWebViewController(environment: environment)
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        
        super.init(nibName : nil, bundle : nil)

        addObserver()
        setupViews()
        loadStreams()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_SHIFT_COURSE_DATES) { _, observer, _ in
            observer.loadStreams()
        }
    }

    private func setupViews() {
        view.addSubview(courseDateBannerView)
        courseDateBannerView.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.trailing)
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(view.snp.top)
            make.height.equalTo(0)
        }
        
        addChild(webController)
        webController.didMove(toParent: self)
        view.addSubview(webController.view)
        
        webController.view.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.trailing)
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(courseDateBannerView.snp.bottom)
            make.bottom.equalTo(view.snp.bottom)
        }
    }
    
    private func loadStreams() {
        if subkind == .Problem {
            let courseBannerRequest = CourseDateBannerAPI.courseDateBannerRequest(courseID: courseID)
            let courseBannerStream = environment.networkManager.streamForRequest(courseBannerRequest)
            courseDateBannerLoader.addBackingStream(courseBannerStream)
            
            courseBannerStream.listen((self), success: { [weak self] courseBannerModel in
                self?.loadCourseDateBannerView(bannerModel: courseBannerModel)
            }, failure: { [weak self] _ in
                self?.hideCourseBannerView()
            })
        }
        
        if !loader.hasBacking {
            let courseQuerierStream = courseQuerier.blockWithID(id: self.blockID).firstSuccess()
            loader.addBackingStream(courseQuerierStream)
            
            courseQuerierStream.listen((self), success: { [weak self] block in
                if let url = block.blockURL {
                    let request = NSURLRequest(url: url as URL)
                    self?.webController.loadRequest(request: request)
                }
                else {
                    self?.webController.showError(error: nil)
                }
            }, failure: { [weak self] error in
                self?.webController.showError(error: error)
            })
        }
    }
    
    private func loadCourseDateBannerView(bannerModel: CourseDateBannerModel) {
        var height: CGFloat = 0
        if bannerModel.hasEnded {
            height = 0
        } else {
            guard let status = bannerModel.bannerInfo.status else { return }
            
            if status == .resetDatesBanner {
                courseDateBannerView.delegate = self
                courseDateBannerView.bannerInfo = bannerModel.bannerInfo
                courseDateBannerView.setupView()
                height = courseDateBannerView.heightForView(width: view.frame.size.width)
            }
        }
        
        courseDateBannerView.snp.remakeConstraints { make in
            make.trailing.equalTo(view.snp.trailing)
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(view.snp.top)
            make.height.equalTo(height)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    private func hideCourseBannerView() {
        courseDateBannerView.snp.remakeConstraints { make in
            make.trailing.equalTo(view.snp.trailing)
            make.leading.equalTo(view.snp.leading)
            make.top.equalTo(view.snp.top)
            make.height.equalTo(0)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    public func preloadData() {
        let _ = self.view
        loadStreams()
    }
    
    private func resetCourseDate() {
        showSnackBar()
        return
        let request = CourseDateBannerAPI.courseDatesResetRequest(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] result  in
            guard let weakSelf = self else { return }
            if let _ = result.error {
                weakSelf.showDateResetSnackBar(message: Strings.Coursedates.ResetDate.errorMessage)
            } else {
                weakSelf.showSnackBar()
                weakSelf.postCourseDateResetNotification()
            }
        }
    }
    
    private func showSnackBar() {
        showDateResetSnackBar(message: Strings.Coursedates.toastSuccessMessage, buttonText: Strings.Coursedates.viewAllDates, showButton: true) { [weak self] in
            if let weakSelf = self {
                weakSelf.environment.router?.showDatesTabController(controller: weakSelf)
                weakSelf.hideSnackBar()
            }
        }
    }
    
    private func postCourseDateResetNotification() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_SHIFT_COURSE_DATES)))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension HTMLBlockViewController: CourseDateBannerViewDelegate {
    func courseShiftDateButtonAction() {
        resetCourseDate()
    }
}
