//
//  PassthroughView.swift
//  edX
//
//  Created by Saeed Bashir on 11/17/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

// View that can't be touched itself. Useful for overlays that contain touchable views
// but that shouldn't otherwise block anything behind them

class PassthroughView : UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        guard view != self else {
            return nil
        }
        return view
    }
}
