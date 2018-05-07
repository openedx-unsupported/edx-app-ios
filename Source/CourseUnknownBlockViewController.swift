//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & OEXAnalyticsProvider
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    var block: CourseBlock?
    var messageView : IconMessageView?
    
    var loader : OEXStream<NSURL?>?
    init(blockID : CourseBlockID?, courseID : String, environment : Environment) {
        self.blockID = blockID
        self.courseID = courseID
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        let courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: self.courseID)
        courseQuerier.blockWithID(id: blockID).extendLifetimeUntilFirstResult (
            success:
            { [weak self] block in
                self?.block = block
                if let video = block.type.asVideo, video.isYoutubeVideo{
                    self?.showYoutubeMessage(buttonTitle: Strings.Video.viewOnYoutube, message: Strings.Video.onlyOnYoutube, icon: Icon.CourseVideos, videoUrl: video.videoURL)
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
            if let videoURL = videoUrl, let url =  URL(string: videoURL) {
                UIApplication.shared.openURL(url as URL)
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
                    UIApplication.shared.openURL(url as URL)
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
        
        self.view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
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
        
        loader = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: self.courseID).blockWithID(id: self.blockID).map {
            return $0.webURL
            }.firstSuccess()
    }
    
    private func logOpenInBrowserEvent() {
        guard let block = block else { return }
        
        environment.analytics.trackOpenInBrowser(withURL: block.blockURL?.absoluteString ?? "", courseID: courseID, blockID: block.blockID, minifiedBlockID: block.minifiedBlockID ?? "", supported: block.multiDevice)
        
    }
    
}
