//
//  TimelinePoint.swift
//  TimelineTableViewCell
//
//  Created by Zheng-Xiang Ke on 2016/10/20.
//  Copyright © 2016年 Zheng-Xiang Ke. All rights reserved.
//

import Foundation
import UIKit

struct TimelinePoint {
    var diameter: CGFloat = 6 {
        didSet {
            if diameter < 0 {
                diameter = 0
            } else if diameter > 100 {
                diameter = 100
            }
        }
    }
    
    var lineWidth: CGFloat = 2 {
        didSet {
            if lineWidth < 0 {
                lineWidth = 0
            } else if lineWidth > 20 {
                lineWidth = 20
            }
        }
    }
    
    var color = OEXStyles.shared().neutralBlackT()
    var strokeColor = OEXStyles.shared().neutralBlackT()
    var position = CGPoint(x: 0, y: 0)

    var isFilled = true
    
    init(diameter: CGFloat, lineWidth: CGFloat, color: UIColor, filled: Bool) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.color = color
        self.isFilled = filled
    }
    
    init() {
        self.init(diameter: 10, lineWidth: 1, color: OEXStyles.shared().neutralBlackT(), filled: true)
    }
    
    func draw(view: UIView) {
        let path = UIBezierPath(ovalIn: CGRect(x: position.x - diameter / 2, y: position.y - diameter / 2, width: diameter, height: diameter))

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = isFilled ? color.cgColor : OEXStyles.shared().neutralWhiteT().cgColor
        shapeLayer.lineWidth = lineWidth

        view.layer.addSublayer(shapeLayer)
    }
}
