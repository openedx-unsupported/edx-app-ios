//
//  CustomPlayerButton.swift
//  edX
//
//  Created by Salman on 05/04/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

class CustomPlayerButton: UIButton {
    private let expandedMargin: CGFloat = 10.0
    
    init() {
        super.init(frame: CGRect.zero)
        showsTouchWhenHighlighted = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let expandedFrame = CGRect(x: 0 - expandedMargin, y: 0 - expandedMargin, width: frame.size.width + (expandedMargin * 2), height: frame.size.height + (expandedMargin * 2))
        return (expandedFrame.contains(point)) ? self : nil
    }
}
