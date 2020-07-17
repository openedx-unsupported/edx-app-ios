//
//  TimelinePoint.swift
//  TimelineTableViewCell
//
//  Created by Zheng-Xiang Ke on 2016/10/20.
//  Copyright © 2016年 Zheng-Xiang Ke. All rights reserved.
//

import Foundation
import UIKit

public struct TimelinePoint {
    public var diameter: CGFloat = 6 {
        didSet {
            if diameter < 0 {
                diameter = 0
            } else if diameter > 100 {
                diameter = 100
            }
        }
    }
    
    public var lineWidth: CGFloat = 2 {
        didSet {
            if lineWidth < 0 {
                lineWidth = 0
            } else if lineWidth > 20 {
                lineWidth = 20
            }
        }
    }
    
    public var color: UIColor = .black
    public var strokeColor: UIColor = .black
    
    private var isFilled = true
    
    internal var position = CGPoint(x: 0, y: 0)
    
    public init(diameter: CGFloat, lineWidth: CGFloat, color: UIColor, filled: Bool) {
        self.diameter = diameter
        self.lineWidth = lineWidth
        self.color = color
        self.isFilled = filled
    }
    
    public init(diameter: CGFloat, color: UIColor, filled: Bool) {
        self.init(diameter: diameter, lineWidth: 4, color: color, filled: filled)
    }
    
    public init(color: UIColor, filled: Bool) {
        self.init(diameter: 6, lineWidth: 4, color: color, filled: filled)
    }
    
    public init() {
        self.init(diameter: 10, lineWidth: 1, color: .black, filled: true)
    }
    
    public func draw(view: UIView) {
        let path = UIBezierPath(ovalIn: CGRect(x: position.x - diameter / 2, y: position.y - diameter / 2, width: diameter, height: diameter))

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = isFilled ? color.cgColor : UIColor.white.cgColor
        shapeLayer.lineWidth = lineWidth

        view.layer.addSublayer(shapeLayer)
    }
}
