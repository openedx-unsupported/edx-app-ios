//
//  OpenOnWebController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class OpenOnWebController {
    public let barButtonItem : UIBarButtonItem
    private weak var ownerViewController : UIViewController?
    
    public init(inViewController controller : UIViewController) {
        let button = UIButton.buttonWithType(.System) as! UIButton
        /// This icon is really small so use a larger size than the default
        button.setImage(Icon.OpenURL.barButtonImage(deltaFromDefault: 4), forState: .Normal)
        button.sizeToFit()
        button.bounds = CGRectMake(0, 0, 20, button.bounds.size.height)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        self.barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.enabled = false
        barButtonItem.accessibilityLabel = OEXLocalizedString("ACCESSIBILITY_OPEN_ON_WEB", nil)
        
        self.ownerViewController = controller
        button.oex_addAction({[weak self] _ in
            self?.confirmOpenURL()
            }, forEvents: .TouchUpInside)
    }
    
    public var URL : NSURL? {
        didSet {
            barButtonItem.enabled = URL != nil
        }
    }
    
    private func openUrlInBrowser(url : NSURL) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    private func confirmOpenURL() {
        if let owner = ownerViewController {
            let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("OPEN_IN_BROWSER", nil), handler: {_ in
                self.URL.map { self.openUrlInBrowser($0) }
                }))
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel, handler: { _ in
                }))
            
            controller.showWithSender(nil, controller: owner, animated: true, completion: nil)
        }

    }

    
}
