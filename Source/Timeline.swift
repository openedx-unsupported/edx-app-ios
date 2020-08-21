//
//  Timeline.swift
//  TimelineTableViewCell
//
//  Created by Zheng-Xiang Ke on 2016/10/21.
//  Copyright © 2016年 Zheng-Xiang Ke. All rights reserved.
//

import Foundation
import UIKit

struct Timeline {
    public var width: CGFloat = 1 {
        didSet {
            if width < 0.0 {
                width = 0.0
            }
        }
    }
    
    public var (topColor, bottomColor) = (UIColor.black, UIColor.black)
    public var leftMargin: CGFloat = 80.0
    public var (start, middle, end) = (CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0))
    
    public init(width: CGFloat, frontColor: UIColor, backColor: UIColor) {
        self.width = width
        self.topColor = frontColor
        self.bottomColor = backColor
        self.leftMargin -= width / 2
    }
    
    public init() {
        self.init(width: 1, frontColor: .black, backColor: .black)
    }
    
    public func draw(view: UIView) {
        draw(view: view, from: start, to: middle, color: topColor)
        draw(view: view, from: middle, to: end, color: bottomColor)
    }
}

// MARK: - Fileprivate Methods
fileprivate extension Timeline {
    func draw(view: UIView, from: CGPoint, to: CGPoint, color: UIColor) {
        let path = UIBezierPath()
        path.move(to: from)
        path.addLine(to: to)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineWidth = width
        shapeLayer.lineCap = .round

        view.layer.addSublayer(shapeLayer)
    }
}
