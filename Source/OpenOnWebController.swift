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
   
    let rightBarButtonItem : UIBarButtonItem
    
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
                Utilities.openUrlInBrowser(urlToOpen)
            })
        }
    }

    
    
    
    
}
