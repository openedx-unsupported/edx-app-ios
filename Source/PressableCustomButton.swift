//
//  PressableCustomButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 20/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

///There is an OS bug that doesn't care for the tintColor of NSTextAttachment as the button's title
///There was also very erratic fading in/out of the .System UIButton when the state changed
///This is a UIButton subclass that mocks the fading in/out of a .System UIButton.
class PressableCustomButton: UIButton {

    static let DEFAULT_ANIMATION_DURATION : TimeInterval = 0.1
    
    private let pressedAction = { (button : AnyObject) -> Void in
        UIView.animate( withDuration: DEFAULT_ANIMATION_DURATION, animations: { () -> Void in
            if let pressableButton = button as? UIButton {
                pressableButton.alpha = 0.3
            }
        })
    }
    
    private let unpressedAction = { (button : AnyObject) -> Void in
        UIView.animate( withDuration: DEFAULT_ANIMATION_DURATION, animations: { () -> Void in
            if let pressableButton = button as? UIButton {
                pressableButton.alpha = 1.0
            }
        })
    }
    
    private func addFadingActions() {
        oex_addAction(pressedAction, for: [.touchDown, .touchDragEnter])
        oex_addAction(unpressedAction, for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
    }
    
    convenience init() {
        self.init(frame : CGRect.zero)
    }
    
    override init(frame : CGRect) {
        super.init(frame: frame)
        addFadingActions()
        
    }
    
    override func oex_removeAllActions() {
        super.oex_removeAllActions()
        addFadingActions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addFadingActions()
    }

    
    
}
