//
//  AccessibilityCLButton.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class AccessibilityCLButton: CLButton {

    private var selectedAccessibilityLabel : String?
    private var normalAccessibilityLabel : String?
    
    override public var selected: Bool {
        didSet {
            if selected {
                if let selectedLabel = selectedAccessibilityLabel {
                    self.accessibilityLabel = selectedLabel
                }
            }
            else {
                if let normalLabel = normalAccessibilityLabel {
                    self.accessibilityLabel = normalLabel
                }
            }
        }
    }
    
    public func setAccessibilityLabelsForStateNormal(normalStateLabel normalLabel: String?, selectedStateLabel selectedLabel: String?) {
        self.selectedAccessibilityLabel = selectedLabel
        self.normalAccessibilityLabel = normalLabel
    }
    
    public override func drawRect(rect: CGRect) {
        let r = UIBezierPath(ovalInRect: rect)
        UIColor.blackColor().colorWithAlphaComponent(0.65).setFill()
        r.fill()
        super.drawRect(rect)
    }
}
