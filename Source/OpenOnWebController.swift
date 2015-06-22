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
    weak var ownerViewController : UIViewController?
    
    init(inViewController controller : UIViewController) {
        let button = UIButton.buttonWithType(.System) as! UIButton
        /// This icon is really small so use a larger size than the default
        button.setImage(Icon.OpenURL.barButtonImage(deltaFromDefault: 4), forState: .Normal)
        button.sizeToFit()
        button.bounds = CGRectMake(0, 0, 20, button.bounds.size.height)
        button.imageEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0)
        
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
            barButtonItem.oex_setAction({[weak self] () -> Void in
                self?.urlToOpen = urlToOpen
                self?.confirmOpenURL()
            })
        }
    }
    
    func openUrlInBrowser(url : NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    func confirmOpenURL() {
        if let owner = ownerViewController {
            let controller = PSTAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("OPEN_IN_BROWSER", nil), handler: {_ in
                self.openUrlInBrowser(self.urlToOpen!)
                }))
            controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), style: .Cancel, handler: { _ in
                }))
            
            controller.showWithSender(nil, controller: owner, animated: true, completion: nil)
        }

    }

    
}
