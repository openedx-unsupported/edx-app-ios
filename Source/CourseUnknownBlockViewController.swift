//
//  CourseUnknownBlockViewController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class CourseUnknownBlockViewController: UIViewController, CourseBlockViewController {
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXAnalyticsProvider>
    
    let environment : Environment

    let blockID : CourseBlockID?
    let courseID : String
    var block: CourseBlock?
    var messageView : IconMessageView?
    
    var player : AVPlayer? = nil
    var playerLayer : AVPlayerLayer? = nil
    var asset : AVAsset? = nil
    var playerItem: AVPlayerItem? = nil
    let playerViewController = AVPlayerViewController()
    
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
                } else {
                    // self?.showError()
                    let video = block.type.asVideo
                    let url:NSURL = NSURL(string: (video?.videoURL)!)!
                    self!.asset = AVAsset(URL: url)
                    self!.playerItem = AVPlayerItem(asset: self!.asset!)
                    self!.player = AVPlayer(playerItem: self!.playerItem)
                    self!.playerLayer = AVPlayerLayer(player: self!.player)
                    self!.playerLayer!.frame = (self?.view.frame)!
                    
                    var frameRect = (self?.view.frame)!
                    frameRect = CGRectMake(0 , 0, frameRect.width, frameRect.height-45)
                    self!.playerViewController.view.frame =  frameRect
                    self!.playerViewController.player = self!.player
                    self!.view.addSubview(self!.playerViewController.view)

                    self!.playVideoIfAvailable()
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        playVideoIfAvailable()
    }
    
    func playVideoIfAvailable() {
        if self.playerViewController.player != nil {
            self.playerViewController.player!.play()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if self.playerViewController.player != nil {
            self.playerViewController.player!.pause()
        }
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
