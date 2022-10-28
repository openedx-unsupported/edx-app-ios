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
    
    func makeAuthView(_ text: String) -> UIView {
        return ExternalProviderView(iconImage: iconImage(), text: text, textStyle: textStyle(), backgroundColor: backgoundColor())
        
        
//        let container = UIView()
//        let iconImageView = UIImageView(image: iconImage())
//        iconImageView.contentMode = .scaleAspectFit
//        let label = UILabel()
//        
//        container.backgroundColor = backgoundColor()
//        container.addSubview(iconImageView)
//        container.addSubview(label)
//        
//        label.attributedText = textStyle().attributedString(withText: text)
//        
//        iconImageView.snp.makeConstraints { make in
//            make.leading.equalTo(container).offset(StandardHorizontalMargin)
//            make.height.equalTo(24)
//            make.width.equalTo(24)
//            make.centerY.equalTo(container)
//        }
//        
//        label.snp.makeConstraints { make in
//            make.leading.equalTo(iconImageView.snp.trailing).offset(StandardHorizontalMargin)
//            make.trailing.equalTo(container)
//            make.height.equalTo(19)
//            make.centerY.equalTo(container)
//        }
//        
//        return container
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
