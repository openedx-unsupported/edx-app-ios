//
//  OpenOnWebController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let OpenURLButtonFontSize : CGFloat = 17.0

class OpenOnWebController: NSObject,UIAlertViewDelegate {
   
    let rightBarButtonItem : UIBarButtonItem
    var urlToOpen : NSURL?
    
    init(inViewController controller : UIViewController) {
        
        let fontAttribute = [NSFontAttributeName : Icon.fontWithSize(OpenURLButtonFontSize)]
        self.rightBarButtonItem = UIBarButtonItem(title: Icon.OpenURL.textRepresentation, style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
        self.rightBarButtonItem.setTitleTextAttributes(fontAttribute, forState: UIControlState.Normal)
        
        controller.navigationItem.setRightBarButtonItem(self.rightBarButtonItem, animated: false)
        rightBarButtonItem.enabled = false
        super.init()
    }
    
    func updateButtonForURL(url : NSURL?)
    {
        rightBarButtonItem.enabled = false
        
        if let urlToOpen = url {
            rightBarButtonItem.enabled = true
            rightBarButtonItem.oex_setAction({ () -> Void in
                self.urlToOpen = urlToOpen
                self.confirmOpenURL()
            })
        }
    }
    
    func openUrlInBrowser(url : NSURL!) {
        UIApplication.sharedApplication().openURL(url)
    }
    
    func confirmOpenURL() {
        var confirmationAlert = UIAlertView()
        confirmationAlert.title = "Confirmation [placeholder]"
        confirmationAlert.message = "Are you sure [placeholder]"
        confirmationAlert.addButtonWithTitle("Cancel")
        confirmationAlert.addButtonWithTitle("Yes")
        confirmationAlert.delegate = self
        
        confirmationAlert.show()
    }

    //MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 { //Cancel
            //Dismiss
        }
        else if buttonIndex == 1 { //Yes
            self.openUrlInBrowser(urlToOpen!)
        }
    }
    
    
    
}
