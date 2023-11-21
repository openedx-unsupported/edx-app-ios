//
//  ChromeCastButtonDelegate.swift
//  edX
//
//  Created by Muhammad Umer on 10/7/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

protocol ChromeCastButtonDelegate {
    var chromeCastButton: GCKUICastButton { get }
    func addChromeCastButton(tintColor: UIColor?)
    func removeChromecastButton()
}

class ChromecastView: UIView, ChromeCastButtonDelegate {
    private var buttonSize: CGFloat = 24
    
    var chromeCastButton: GCKUICastButton {
        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        castButton.oex_addAction({ _ in
            ChromeCastManager.shared.viewExpanded = true
        }, for: .touchUpInside)
        return castButton
    }
    
    func addChromeCastButton(tintColor: UIColor? = nil) {
        let castButton = chromeCastButton
        if let tintColor = tintColor {
            castButton.tintColor = tintColor
        }
        addSubview(castButton)
        castButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(buttonSize)
        }
    }
    
    func removeChromecastButton() {
        subviews.first(where: { $0 is GCKUICastButton })?.removeFromSuperview()
    }
}
