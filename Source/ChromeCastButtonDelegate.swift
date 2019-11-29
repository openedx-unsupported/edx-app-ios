//
//  ChromeCastButtonDelegate.swift
//  edX
//
//  Created by Muhammad Umer on 10/7/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

/// Chrome cast button will always be added to the index one in case of more than one right navbar items
let ChromeCastButtonIndex = 1

/// Handles chrome cast button addition and removal from the navigation bar
/// This protocol will handle button addition/removal to navigation bar without consedering the video cast state
protocol ChromeCastButtonDelegate {
    var chromeCastButton: GCKUICastButton { get }
    var chromeCastButtonItem: UIBarButtonItem { get }
    func addChromeCastButton()
    func removeChromecastButton()
}

/// Handles chrome cast button addition and removal from the navigation bar
/// This protocol will handle button addition/removal to navigation bar when the video is being casted: connected state
protocol ChromeCastConnectedButtonDelegate: ChromeCastButtonDelegate {
}

/// Default implementation of Protocol ChromeCastButtonDelegate,
/// This way Controller just needs to add 'ChromeCastButtonDelegate' and it will have all desired functionality
extension ChromeCastButtonDelegate where Self: UIViewController {
    /// Provides Reference to ChromeCastButton that will be added to Navigationbar
    var chromeCastButton: GCKUICastButton {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        castButton.tintColor = OEXStyles.shared().primaryBaseColor()
        castButton.oex_addAction({ _ in
            ChromeCastManager.shared.viewExpanded = true
        }, for: .touchUpInside)
        return castButton
    }
    
    var chromeCastButtonItem: UIBarButtonItem {
        return UIBarButtonItem(customView: chromeCastButton)
    }
    
    func addChromeCastButton() {
        guard let count = navigationItem.rightBarButtonItems?.count, count >= 1 else {
            navigationItem.rightBarButtonItem = chromeCastButtonItem
            return
        }
        
        var isAdded = false
        navigationItem.rightBarButtonItems?.forEach({ item in
            if item.customView is GCKUICastButton {
                isAdded = true
                return
            }
        })
        
        if isAdded { return }
        
        navigationItem.rightBarButtonItems?.insert(chromeCastButtonItem, at: ChromeCastButtonIndex)
    }
    
    func removeChromecastButton() {
        guard let navigationBarItems = navigationItem.rightBarButtonItems else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        for (index, element) in navigationBarItems.enumerated() {
            if element.customView is GCKUICastButton {
                navigationItem.rightBarButtonItems?.remove(at: index)
                break
            }
        }
    }
}
