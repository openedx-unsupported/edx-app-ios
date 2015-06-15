//
//  OpenOnWebController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class OpenOnWebController: NSObject {
   
    let barButtonItem : UIBarButtonItem
    var urlToOpen : NSURL?
    var ownerViewController : UIViewController!
    
    init(inViewController controller : UIViewController) {
        let defaultFont = Icon.fontWithTitleSize()
        let button = UIButton.buttonWithType(.System) as! UIButton
        /// This icon is really small so use a larger size than the default
        button.titleLabel?.font = defaultFont.fontWithSize(defaultFont.pointSize + 3.5)
        button.setTitle(Icon.OpenURL.textRepresentation, forState: .Normal)
        button.sizeToFit()
        button.bounds = CGRectMake(0, 0, 20, button.bounds.size.height)
        button.titleEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        
        self.barButtonItem = UIBarButtonItem(customView: button)
        barButtonItem.enabled = false
        
        self.ownerViewController = controller
        super.init()
    }
    
    func updateButtonForURL(url : NSURL?)
    {
        barButtonItem.enabled = false
        
        if let urlToOpen = url {
            barButtonItem.enabled = true
            barButtonItem.oex_setAction({ () -> Void in
                self.urlToOpen = urlToOpen
                self.confirmOpenURL()
            })
        }
    }
    
    func openUrlInBrowser(url : NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    func confirmOpenURL() {
        
        let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("OPEN_IN_BROWSER", nil), handler: { [weak self] _ in
            self!.openUrlInBrowser(self!.urlToOpen!)
        }))
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel, handler: { [weak self] _ in
            }))
        
        controller.showWithSender(nil, controller: ownerViewController, animated: true, completion: nil)

    }

    
}
