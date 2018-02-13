//
//  ProgressController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 15/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
/// Responsible for the size of the CircularProgressView as well as the button
private let ProgressViewFrame = CGRect(x: 0, y: 0, width: 30, height: 30)

/// To be used whenever we want to show the download progress of the Videos.
public class ProgressController: NSObject {
   
    private let circularProgressView : DACircularProgressView

    private let downloadButton : UIButton
    
    private var dataInterface : OEXInterface?
    private weak var router : OEXRouter?
    private weak var owner : UIViewController?
    
    lazy var percentFormatter: NumberFormatter = {
       let pf = NumberFormatter()
        pf.numberStyle = NumberFormatter.Style.percent
        return pf
    }()
    
    private var downloadProgress : CGFloat {
        return CGFloat(self.dataInterface?.totalProgress ?? 0)
    }
    
    init(owner : UIViewController, router : OEXRouter?, dataInterface : OEXInterface?) {
        circularProgressView = DACircularProgressView(frame: ProgressViewFrame)
        circularProgressView.progressTintColor = OEXStyles.shared().progressBarTintColor
        circularProgressView.trackTintColor = OEXStyles.shared().progressBarTrackTintColor
        
        downloadButton = UIButton(type: .system)
        downloadButton.setImage(UIImage(named: "ic_download_arrow"), for: .normal)
        downloadButton.tintColor = OEXStyles.shared().navigationItemTintColor()
        downloadButton.accessibilityLabel = Strings.accessibilityDownloadProgressButton(percentComplete: 0, formatted: nil)
        downloadButton.accessibilityHint = Strings.Accessibility.showCurrentDownloadsButtonHint
        downloadButton.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitUpdatesFrequently
        downloadButton.frame = ProgressViewFrame
        
        
        circularProgressView.addSubview(downloadButton)
        super.init()
    
        self.dataInterface = dataInterface
        self.router = router
        self.owner = owner
        
        self.dataInterface?.progressViews.add(circularProgressView)
        self.dataInterface?.progressViews.add(downloadButton)
        
        downloadButton.oex_addAction({ [weak self](_) -> Void in
            if let owner = self?.owner {
                self?.router?.showDownloads(from: owner)
            }
            }, for: .touchUpInside)
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXDownloadProgressChanged.rawValue) { (_, observer, _) -> Void in
            observer.updateProgressDisplay()
        }
    }
    
    private func updateProgressDisplay() {
        //Assuming there wouldn't be a situation where we'd want to force-hide the views. Also, this will automatically show the View when reachability is back on or any other situation where we hid it unwillingly.
        showProgessView()
        circularProgressView.setProgress(downloadProgress, animated: true)
        let percentStr = percentFormatter.string(from: NSNumber(value: Float(downloadProgress)))!
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
        circularProgressView.isHidden = true
        downloadButton.isHidden = true
    }
    
    func showProgessView() {
        circularProgressView.isHidden = false
        downloadButton.isHidden = false
    }
}
