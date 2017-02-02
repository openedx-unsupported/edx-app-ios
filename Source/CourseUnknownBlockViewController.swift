//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXAnalyticsProvider>
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    var block: CourseBlock?
    var messageView : IconMessageView?
    
    var loader : Stream<NSURL?>?
    init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID)
        courseQuerier.blockWithID(blockID).extendLifetimeUntilFirstResult (
            success:
            { [weak self] block in
                self?.block = block
                if let video = block.type.asVideo where video.isYoutubeVideo{
                    self?.showYoutubeMessage(Strings.Video.viewOnYoutube, message: Strings.Video.onlyOnYoutube, icon: Icon.CourseModeVideo, videoUrl: video.videoURL)
                }
                else {
                    self?.showError()
                }
            },
            failure: {[weak self] _ in
                self?.showError()
            }
        )
    }
    
    private func showYoutubeMessage(buttonTitle: String, message: String, icon: Icon, videoUrl: String?) {
        messageView = IconMessageView(icon: icon, message: message)
        messageView?.buttonInfo = MessageButtonInfo(title : buttonTitle)
        {
            if let videoURL = videoUrl, url =  NSURL(string: videoURL) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        
        view.addSubview(messageView!)
    }
    
    private func showError() {
        messageView = IconMessageView(icon: Icon.CourseUnknownContent, message: Strings.courseContentUnknown)
        messageView?.buttonInfo = MessageButtonInfo(title : Strings.openInBrowser)
        {
            [weak self] in
            self?.loader?.listen(self!, success : {url -> Void in
                if let url = url {
                    UIApplication.sharedApplication().openURL(url)
                    self?.logOpenInBrowserEvent()
                }
                }, failure : {_ in
            })
        }
        
        view.addSubview(messageView!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
    }
    
    override func updateViewConstraints() {
        
        if  self.isVerticallyCompact() {
            applyLandscapeConstraints()
        }
        else{
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        messageView?.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
    }
    
    private func applyLandscapeConstraints() {
        messageView?.snp_remakeConstraints { (make) -> Void in
            make.edges.equalTo(view)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(view.snp_bottom).offset(-barHeight)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if loader?.value == nil {
            loader = environment.dataManager.courseDataManager.querierForCourseWithID(self.courseID).blockWithID(self.blockID).map {
                return $0.webURL
            }.firstSuccess()
        }
    }
    
    private func logOpenInBrowserEvent() {
        guard let block = block else { return }
        
        environment.analytics.trackOpenInBrowserWithURL(block.blockURL?.absoluteString ?? "", courseID: courseID, blockID: block.blockID, minifiedBlockID: block.minifiedBlockID ?? "", supported: block.multiDevice)
        
    }
    
}
