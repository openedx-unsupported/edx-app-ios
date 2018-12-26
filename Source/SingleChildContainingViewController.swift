//
//  SingleChildContainingViewController.swift
//  edX
//
//  Created by Akiva Leffert on 2/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class SingleChildContainingViewController : UIViewController {
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.childViewControllers.last
    }

    override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.childViewControllers.last
    }

    override var shouldAutorotate: Bool {
        return self.childViewControllers.last?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.childViewControllers.last?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        handleDynamicTypeNotification()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func handleDynamicTypeNotification() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIContentSizeCategoryDidChange.rawValue) { [weak self] (_, _, _) in
            if let weakSelf = self {
                weakSelf.view.updateFontsOfSubviews(v: weakSelf.view)
                weakSelf.view.layoutIfNeeded()
            }
            
            NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE)))
        }
    }
}
