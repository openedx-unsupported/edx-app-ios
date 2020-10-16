//
//  FillBackgroundLayoutManager.swift
//  edX
//
//  Created by Muhammad Umer on 08/10/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

class FillBackgroundLayoutManager: NSLayoutManager {
    private var borderColor: UIColor = .clear
    private var lineWidth: CGFloat = 0.5
    private var cornerRadius = 5
    
    func set(borderColor: UIColor, lineWidth: CGFloat, cornerRadius: Int) {
        self.borderColor = borderColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
    }
    
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        guard let _ = textStorage,
              let currentCGContext = UIGraphicsGetCurrentContext() else {
            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
            return
        }
        
        currentCGContext.saveGState()
                
        for i in 0..<rectCount  {
            
            var previousRect = CGRect.zero
            let currentRect = rectArray[i]

            if i > 0 {
                previousRect = rectArray[i - 1]
            }
            
            let frame = rectArray[i]
            let rect = CGRect.init(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: frame.size.height + 2)
            
            let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
            let rectanglePath = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: cornerRadii)
            color.set()
            
            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)
            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)
            
            let overlappingLine = UIBezierPath()
            let leftVerticalJoiningLine = UIBezierPath()
            let rightVerticalJoiningLine = UIBezierPath()
            let leftVerticalJoiningLineShadow = UIBezierPath()
            let rightVerticalJoiningLineShadow = UIBezierPath()
                        
            if previousRect != .zero, (currentRect.maxX - previousRect.minX) > CGFloat(cornerRadius) {
                let yDifference = currentRect.minY - previousRect.maxY
                overlappingLine.move(to: CGPoint(x: max(previousRect.minX, currentRect.minX) + lineWidth / 2, y: previousRect.maxY + yDifference / 2))
                overlappingLine.addLine(to: CGPoint(x: min(previousRect.maxX, currentRect.maxX) - lineWidth / 2, y: previousRect.maxY + yDifference / 2))

                let leftX = max(previousRect.minX, currentRect.minX)
                let rightX = min(previousRect.maxX, currentRect.maxX)

                leftVerticalJoiningLine.move(to: CGPoint(x: leftX, y: previousRect.maxY))
                leftVerticalJoiningLine.addLine(to: CGPoint(x: leftX, y: currentRect.minY))
                rightVerticalJoiningLine.move(to: CGPoint(x: rightX, y: previousRect.maxY))
                rightVerticalJoiningLine.addLine(to: CGPoint(x: rightX, y: currentRect.minY))

                let leftShadowX = max(previousRect.minX, currentRect.minX) + lineWidth
                let rightShadowX = min(previousRect.maxX, currentRect.maxX) - lineWidth

                leftVerticalJoiningLineShadow.move(to: CGPoint(x: leftShadowX, y: previousRect.maxY))
                leftVerticalJoiningLineShadow.addLine(to: CGPoint(x: leftShadowX, y: currentRect.minY))
                rightVerticalJoiningLineShadow.move(to: CGPoint(x: rightShadowX, y: previousRect.maxY))
                rightVerticalJoiningLineShadow.addLine(to: CGPoint(x: rightShadowX, y: currentRect.minY))
            }
            
            currentCGContext.setLineWidth(lineWidth * 4)
            currentCGContext.setStrokeColor(borderColor.cgColor)
            currentCGContext.addPath(leftVerticalJoiningLineShadow.cgPath)
            currentCGContext.addPath(rightVerticalJoiningLineShadow.cgPath)
            currentCGContext.drawPath(using: .stroke)
            currentCGContext.setShadow(offset: .zero, blur: 0, color: UIColor.clear.cgColor)
            currentCGContext.setLineWidth(lineWidth)
            currentCGContext.setStrokeColor(borderColor.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.addPath(leftVerticalJoiningLine.cgPath)
            currentCGContext.addPath(rightVerticalJoiningLine.cgPath)
            currentCGContext.drawPath(using: .stroke)
            currentCGContext.setShadow(offset: .zero, blur: 0, color: UIColor.clear.cgColor)
            currentCGContext.setStrokeColor(color.cgColor)
            currentCGContext.addPath(overlappingLine.cgPath)
        }
        currentCGContext.restoreGState()
    }
}
