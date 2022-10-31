//
//  AppleAuthProvider.swift
//  edX
//
//  Created by Salman on 20/08/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

@objc class AppleAuthProvider: NSObject, OEXExternalAuthProvider {

    @objc static let backendName = "apple-id"
    override init() {
        super.init()
    }
    
    var displayName: String  {
        return Strings.apple
    }
    
    var backendName: String  {
        return AppleAuthProvider.backendName
    }
    
    func authView(withTitle title: String) -> UIView {
        return ExternalProviderButtonView(iconImage: iconImage(), title: title, textStyle: textStyle(), backgroundColor: backgoundColor())
    }
    
    func iconImage() -> UIImage {
        return UIImage(named: "icon_apple") ?? UIImage()
    }
    
    func backgoundColor() -> UIColor {
        UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
    }
    
    func textStyle() -> OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralWhiteT())
    }
    
    func authorizeService(from controller: UIViewController, requestingUserDetails loadUserDetails: Bool, withCompletion completion: @escaping (String?, OEXRegisteringUserDetails?, Error?) -> Void) {
        AppleSocial.shared.loginFromController(controller: controller) { userdetails, token, error in
            completion(token,userdetails, error)
        }
    }
}
