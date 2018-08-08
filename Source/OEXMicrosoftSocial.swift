//
//  OEXMicrosoftSocial.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class OEXMicrosoftSocial: NSObject {

    override init() {
        super.init()
    
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue, action: { (_, observer, _) in
                //observer?.logout()
            })
    }
    
    func loginFromController(controller: UIViewController, completionHandler:(()->Void)? = nil) {
        
    }
}
