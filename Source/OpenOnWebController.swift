//
//  OpenOnWebController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol OpenOnWebControllerDelegate : class {
    func presentationControllerForOpenOnWebController(controller : OpenOnWebController) -> UIViewController
}


public class OpenOnWebController {

    public struct Info {
        private let courseID : String
        private let blockID : CourseBlockID
        private let supported : Bool
        private let URL : NSURL?
        
        public init(courseID : String, blockID : CourseBlockID, supported : Bool, URL : NSURL?) {
            self.courseID = courseID
            self.blockID = blockID
            self.supported = supported
            self.URL = URL
        }
    }
    

    
    public let barButtonItem : UIBarButtonItem
    private weak var delegate : OpenOnWebControllerDelegate?
    
    public init(delegate : OpenOnWebControllerDelegate) {
        let button = UIButton(type: .System)
        /// This icon is really small so use a larger size than the default
        button.setImage(Icon.OpenURL.barButtonImage(deltaFromDefault: 4), forState: .Normal)
        button.sizeToFit()
        button.bounds = CGRectMake(0, 0, 20, button.bounds.size.height)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        self.barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.enabled = false
        barButtonItem.accessibilityLabel = OEXLocalizedString("OPEN_IN_BROWSER", nil)
        
        self.delegate = delegate
        button.oex_addAction({[weak self] _ in
            self?.confirmOpenURL()
            }, forEvents: .TouchUpInside)
    }
    
    public var info : Info? {
        didSet {
            barButtonItem.enabled = info?.URL != nil
        }
    }
    
    private func openUrlInBrowser() {
        if let info = info, url = info.URL {
            OEXAnalytics.sharedAnalytics().trackOpenInBrowserWithURL(info.URL?.absoluteString, courseID: info.courseID, blockID: info.blockID, supported: info.supported)
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    private func confirmOpenURL() {
        if info?.URL != nil {
            let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("OPEN_IN_BROWSER", nil))
                { _ in
                    self.openUrlInBrowser()
                }
            )
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel)
                {_ in
                }
            )
            let container = self.delegate?.presentationControllerForOpenOnWebController(self)
            controller.showWithSender(nil, controller: container, animated: true, completion: nil)
        }

    }

    
}
