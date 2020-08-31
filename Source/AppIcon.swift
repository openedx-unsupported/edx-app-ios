//
//  AppIcon.swift
//  edX
//
//  Created by Muhammad Umer on 31/08/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

@objc class AppIcon: NSObject {
    @objc static let shared = AppIcon()
    
    @objc func changeIcon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if #available(iOS 10.3, *) {
                if UIApplication.shared.supportsAlternateIcons {
                    UIApplication.shared.setAlternateIconName("Bars2") { error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("App Icon changed!")
                        }
                    }
                }
            }
        }
    }
}
