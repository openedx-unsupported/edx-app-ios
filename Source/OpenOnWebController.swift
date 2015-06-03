//
//  OpenOnWebController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let OpenURLButtonFontSize : CGFloat = 17.0

class OpenOnWebController: NSObject {
   
    let barButtonItem : UIBarButtonItem
    var urlToOpen : NSURL?
    var ownerViewController : UIViewController!
    
    init(inViewController controller : UIViewController) {
        
        let fontAttribute = [NSFontAttributeName : Icon.fontWithSize(OpenURLButtonFontSize)]
        self.barButtonItem = UIBarButtonItem(title: Icon.OpenURL.textRepresentation, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        self.barButtonItem.setTitleTextAttributes(fontAttribute, forState: UIControlState.Normal)
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
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("OPEN_IN_BROWSER", nil) , handler: { [weak self] _ in
            self!.openUrlInBrowser(self!.urlToOpen!)
        }))
        controller.addAction(PSTAlertAction(title: OEXLocalizedString("CANCEL", nil), handler: { [weak self] _ in
            }))
        
        controller.showWithSender(nil, controller: ownerViewController, animated: true, completion: nil)

    }

    
}
