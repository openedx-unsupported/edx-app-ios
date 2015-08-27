//
//  OEXCheckBox.swift
//  edX
//
//  Created by Michael Katz on 8/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

//@IBDesignable
public class OEXCheckBox: UIButton {
    
    @IBInspectable public var checked: Bool = false {
        didSet {
            updateState()
        }
    }
    
    private func _setup() {
        addTarget(self, action: "tapped", forControlEvents: .TouchUpInside)
        updateState()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    private func updateState() {
        let newIcon = checked ? Icon.CheckCircle : Icon.CheckCircleO
        let size = min(self.bounds.width, self.bounds.height)
        let image = newIcon.imageWithFontSize(size)
        setImage(image, forState: .Normal)
    }
    
    func tapped() {
        checked = !checked
        sendActionsForControlEvents(.ValueChanged)
    }
}
