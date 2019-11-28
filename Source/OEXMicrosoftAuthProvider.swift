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
        return Strings.microsoft
    }
    
    var backendName: String  {
        return "azuread-oauth2"
    }
    
    func freshAuthButton() -> UIButton {
        let button = OEXExternalAuthProviderButton()
        button.provider = self
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        button.setImage(UIImage(named: "icon_microsoft_white"), for: .normal)
        button.useBackgroundImage(of: UIColor(red: 47.0/255.0, green: 47.0/255.0, blue: 47.0/255.0, alpha: 1.0))
        return button
    }
    
    func authorizeService(from controller: UIViewController, requestingUserDetails loadUserDetails: Bool, withCompletion completion: @escaping (String?, OEXRegisteringUserDetails?, Error?) -> Void) {
        MicrosoftSocial.shared.loginFromController(controller: controller) { (token, error) in
            if let error = error {
                completion(token, nil, error)
            } else if loadUserDetails {
                // load user details
                MicrosoftSocial.shared.requestUserProfileInfo(completion: { (user) in
                    let profile = OEXRegisteringUserDetails()
                    profile.name = user.name
                    profile.email = user.displayableId
                    completion(token, profile, error)
                })
            } else {
                completion(token, nil, error)
            }
        }
    }
}
