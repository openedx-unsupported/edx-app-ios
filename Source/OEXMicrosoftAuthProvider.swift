//
//  OEXMicrosoftAuthProvider.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit


class OEXMicrosoftAuthProvider: NSObject, OEXExternalAuthProvider {

    
    override init() {
        super.init()
    }
    
    var displayName: String  {
        return ""
    }
    
    var backendName: String  {
        return ""
    }
    
    func freshAuthButton() -> UIButton {
        let button = OEXExternalAuthProviderButton(frame: CGRect.zero)
        button.provider = self
        // Because of the '+' the G icon is off center. This accounts for that.
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 3, 0, -3)
        button.setImage(UIImage(named: "icon_google_white"), for: .normal)
        //button.useBackgroundImageOfColor(googleRed())
        
        return button
    }
    
    func authorizeService(from controller: UIViewController, requestingUserDetails loadUserDetails: Bool, withCompletion completion: @escaping (String, OEXRegisteringUserDetails, Error) -> Void) {
        
    }
    
}
