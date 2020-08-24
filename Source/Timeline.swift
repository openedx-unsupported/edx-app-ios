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
    
    public var topColor = UIColor.black
    public var bottomColor = UIColor.black
    public var leftMargin: CGFloat = 80.0
    public var start = CGPoint.zero
    public var middle = CGPoint.zero
    public var end = CGPoint.zero
    
    public init(width: CGFloat, topColor: UIColor, bottomColor: UIColor) {
        self.width = width
        self.topColor = topColor
        self.bottomColor = bottomColor
        self.leftMargin -= width / 2
    }
    
    public init() {
        self.init(width: 1, topColor: .black, bottomColor: .black)
    }
    
    func draw(view: UIView) {
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
