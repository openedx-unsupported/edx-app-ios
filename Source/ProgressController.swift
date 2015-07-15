//
//  ProgressController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 15/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
/// Responsible for the size of the CircularProgressView as well as the button
private let ProgressViewFrame = CGRectMake(0, 0, 30, 30)

/// To be used whenever we want to show the download progress of the Videos.
public class ProgressController: NSObject {
   
    private let circularProgressView : DACircularProgressView
    ///Action to be set by the owner
    public let downloadButton : UIButton
    
    private var dataInterface : OEXInterface?
    private var router : OEXRouter?
    
    private var downloadProgress : CGFloat {
        get {
            return CGFloat(self.dataInterface!.totalProgress)
        }
        
        set {
            //Assuming there wouldn't be a situation where we'd want to force-hide the views. Also, this will automatically show the View when reachability is back on or any other situation where we hid it unwillingly.
            showProgessView()
            circularProgressView.setProgress(newValue, animated: true)
        }
        
    }
    
    init(owner : UIViewController, router : OEXRouter, dataInterface : OEXInterface) {
        circularProgressView = DACircularProgressView(frame: ProgressViewFrame)
        circularProgressView.progressTintColor = OEXStyles.sharedStyles().progressBarTintColor
        circularProgressView.trackTintColor = OEXStyles.sharedStyles().progressBarTrackTintColor
        
        downloadButton = UIButton.buttonWithType(.Custom) as! UIButton
        downloadButton.setImage(UIImage(named: "ic_download_arrow"), forState: .Normal)
        downloadButton.frame = ProgressViewFrame
        
        circularProgressView.addSubview(downloadButton)
        super.init()
    
        self.dataInterface = dataInterface
        self.router = router
        
        self.dataInterface!.progressViews.addObject(circularProgressView)
        self.dataInterface!.progressViews.addObject(downloadButton)
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadProgressChangedNotification) { [weak self](_, observer, _) -> Void in
            observer.downloadProgress = observer.downloadProgress
        }
    }
    
    func navigationItem() -> UIBarButtonItem {
        return UIBarButtonItem(customView: circularProgressView)
    }
    
    func progressView() -> UIView {
        return circularProgressView
    }
    
    func hideProgessView() {
        circularProgressView.hidden = true
        downloadButton.hidden = true
    }
    
    func showProgessView() {
        circularProgressView.hidden = false
        downloadButton.hidden = false
    }
}
