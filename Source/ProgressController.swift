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

    private let downloadButton : UIButton
    
    private var dataInterface : OEXInterface?
    private weak var router : OEXRouter?
    private weak var owner : UIViewController?
    
    lazy var percentFormatter: NSNumberFormatter = {
       let pf = NSNumberFormatter()
        pf.numberStyle = NSNumberFormatterStyle.PercentStyle
        return pf
    }()
    
    private var downloadProgress : CGFloat {
        return CGFloat(self.dataInterface?.totalProgress ?? 0)
    }
    
    init(owner : UIViewController, router : OEXRouter?, dataInterface : OEXInterface?) {
        circularProgressView = DACircularProgressView(frame: ProgressViewFrame)
        circularProgressView.progressTintColor = OEXStyles.sharedStyles().progressBarTintColor
        circularProgressView.trackTintColor = OEXStyles.sharedStyles().progressBarTrackTintColor
        
        downloadButton = UIButton(type: .System)
        downloadButton.setImage(UIImage(named: "ic_download_arrow"), forState: .Normal)
        downloadButton.tintColor = OEXStyles.sharedStyles().navigationItemTintColor()
        downloadButton.accessibilityLabel = Strings.accessibilityDownloadProgressButton(percentComplete: 0, formatted: nil)
        downloadButton.accessibilityHint = Strings.accessibilityDownloadProgressButtonHint
        downloadButton.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently
        downloadButton.frame = ProgressViewFrame
        
        
        circularProgressView.addSubview(downloadButton)
        super.init()
    
        self.dataInterface = dataInterface
        self.router = router
        self.owner = owner
        
        self.dataInterface?.progressViews.addObject(circularProgressView)
        self.dataInterface?.progressViews.addObject(downloadButton)
        
        downloadButton.oex_addAction({ [weak self](_) -> Void in
            if let owner = self?.owner {
                self?.router?.showDownloadsFromViewController(owner)
            }
            }, forEvents: .TouchUpInside)
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXDownloadProgressChangedNotification) { (_, observer, _) -> Void in
            observer.updateProgressDisplay()
        }
    }
    
    private func updateProgressDisplay() {
        //Assuming there wouldn't be a situation where we'd want to force-hide the views. Also, this will automatically show the View when reachability is back on or any other situation where we hid it unwillingly.
        showProgessView()
        circularProgressView.setProgress(downloadProgress, animated: true)
        let percentStr = percentFormatter.stringFromNumber(downloadProgress)!
        let numeric = Int(downloadProgress * 100)
        downloadButton.accessibilityLabel = Strings.accessibilityDownloadProgressButton(percentComplete: numeric, formatted: percentStr)
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
