//
//  DownloadProgressViewController.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public protocol DownloadProgressViewControllerDelegate : class {
    func downloadProgressControllerChoseShowDownloads(controller : DownloadProgressViewController)
}

public class DownloadProgressViewController : ViewTopMessageController {
    
    public class Environment {
        private let interface : OEXInterface?
        private let reachability : Reachability
        private let styles : OEXStyles
        
        public init(interface : OEXInterface?, reachability : Reachability = InternetReachability(), styles : OEXStyles) {
            self.interface = interface
            self.reachability = reachability
            self.styles = styles
        }
    }
    
    var delegate : DownloadProgressViewControllerDelegate?

    public init(environment : Environment) {
        let messageView = CourseOutlineHeaderView(frame: CGRectZero, styles: environment.styles, titleText: OEXLocalizedString("VIDEO_DOWNLOADS_IN_PROGRESS", nil), subtitleText: nil, shouldShowSpinner: true)
        
        super.init(messageView : messageView, active : {
            let progress = environment.interface?.totalProgress ?? 0
            return progress != 0 && progress != 1 && environment.reachability.isReachable()
        })
        messageView.setViewButtonAction {[weak self] _ in
            self.map {
                $0.delegate?.downloadProgressControllerChoseShowDownloads($0)
            }
        }
        
        for notification in [OEXDownloadProgressChangedNotification, OEXDownloadEndedNotification, kReachabilityChangedNotification] {
            NSNotificationCenter.defaultCenter().oex_addObserver(self, name: notification) { (_, observer, _) -> Void in
                observer.updateAnimated()
            }
        }
    }

}