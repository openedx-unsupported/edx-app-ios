//
//  UIView+Shimmer.swift
//  UIView-Shimmer
//
//  Created by Ömer Faruk Öztürk on 8.01.2021.
//

import UIKit

protocol ShimmerView {
    func setShimmerAnimation(_ animate: Bool, shimmerColor: UIColor, roundCorners: Bool)
    func removeShimmerAnimation(backgroundColor: UIColor?)
}

extension ShimmerView {
    func setShimmerAnimation(_ animate: Bool, shimmerColor: UIColor, roundCorners: Bool) { }
    func removeShimmerAnimation(backgroundColor: UIColor? = nil) { }
}

extension ShimmerView where Self: UIView {
    private func getFrame() -> CGRect {
        guard let label = self as? UILabel else {
            return bounds
        }
        let width: CGFloat = intrinsicContentSize.width
        var horizontalX: CGFloat
        switch label.textAlignment {
        case .center:
            horizontalX = bounds.midX - width / 2
        case .right:
            horizontalX = bounds.width - width
        default:
            horizontalX = 0
        }
        
        return CGRect(x: horizontalX, y: 0, width: width, height: intrinsicContentSize.height)
    }
    
    func setShimmerAnimation(_ animate: Bool, shimmerColor: UIColor? = nil, roundCorners: Bool = false) {
        let currentShimmerLayer = layer.sublayers?.first(where: { $0.name == "shimmerLayer" })
        if animate {
            if currentShimmerLayer != nil { return }
        } else {
            currentShimmerLayer?.removeFromSuperlayer()
            return
        }
        
        let baseShimmeringColor = shimmerColor ?? superview?.backgroundColor
        guard let color = baseShimmeringColor else { return }
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.name = "shimmerLayer"
        gradientLayer.frame = getFrame()
        gradientLayer.cornerRadius = roundCorners ? min(bounds.height / 2, 5) : 0
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        let gradientColorOne = color.withAlphaComponent(0.5).cgColor
        let gradientColorTwo = color.withAlphaComponent(0.8).cgColor
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorOne]
        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
        gradientLayer.zPosition = CGFloat(Float.greatestFiniteMagnitude)
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.repeatCount = .infinity
        animation.duration = 1.25
        gradientLayer.add(animation, forKey: animation.keyPath)
    }
    
    func removeShimmerAnimation(backgroundColor: UIColor? = nil) {
        layer.sublayers?.first(where: { $0.name == "shimmerLayer" })?.removeFromSuperlayer()
        self.backgroundColor = backgroundColor
    }
}
