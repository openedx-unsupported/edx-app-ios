//
//  UIButton+Animations.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

extension UIButton {
    func setAttributedTitle(title : NSAttributedString, forState state: UIControlState, animated : Bool) {
        if !animated {
            UIView.performWithoutAnimation({ () -> Void in
                self.setAttributedTitle(title, for: state)
                self.layoutIfNeeded()
            })
        }
        else {
            self.setAttributedTitle(title, for: state)
        }
    }
}
