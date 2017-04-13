//
//  RatingView.swift
//  edX
//
//  Created by Danial Zahid on 1/25/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private let imageSize : CGFloat = 40.0

class RatingView: UIControl {

    typealias RatingViewShouldBeginGestureRecognizerBlock = (UIGestureRecognizer) -> Bool
    
    private let maximumValue : CGFloat = 5
    private let minimumValue : CGFloat = 0
    private let spacing : CGFloat = 5
    var value : Int = 0
    
    let emptyImage = Icon.StarEmpty.imageWithFontSize(size: imageSize)
    let filledImage = Icon.StarFilled.imageWithFontSize(size: imageSize)
    
    var shouldBeginGestureRecognizerBlock : RatingViewShouldBeginGestureRecognizerBlock?
    
    init() {
        super.init(frame: CGRect.zero)
        isAccessibilityElement = true
        accessibilityLabel = Strings.AppReview.ratingControlAccessibilityLabel
        accessibilityHint = Strings.AppReview.ratingControlAccessibilityHint
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Action generators
    func setRatingValue(value: Int) {
        willChangeValue(forKey: "value")
        if self.value != value && value >= Int(minimumValue) && value <= Int(maximumValue) {
            self.value = value
            sendActions(for: UIControlEvents.valueChanged)
            setNeedsDisplay()
        }
        didChangeValue(forKey: "value")
    }
    
    //MARK: - Draw methods
    private func drawImageWithFrame(frame: CGRect, tintColor: UIColor, highlighted: Bool) {
        let image : UIImage = highlighted ? filledImage : emptyImage
        drawImage(image: image, frame: frame, tintColor: tintColor)
    }
    
    private func drawImage(image: UIImage, frame: CGRect, tintColor: UIColor) {
        if image.renderingMode == UIImageRenderingMode.alwaysTemplate {
            tintColor.setFill()
        }
        image.draw(in: frame)
    }
    
    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(backgroundColor?.cgColor ?? UIColor.white.cgColor)
            context.fill(rect)
        }
        
        let availableWidth = rect.size.width - (spacing * (maximumValue - 1)) - 2
        let cellWidth = (availableWidth / maximumValue)
        let starSide = (cellWidth <= rect.size.height) ? cellWidth : rect.size.height
        
        for idx in 0 ..< Int(maximumValue) {
            var pointX = (cellWidth * CGFloat(idx)) + (cellWidth / 2)
            pointX += (spacing * CGFloat(idx)) + 1
            let center = CGPoint(x: pointX, y: rect.size.height/2)
            let frame = CGRect(x: center.x - starSide/2, y: center.y - starSide/2, width: starSide, height: starSide)
            let highlighted = (idx + 1 <= value)
            drawImageWithFrame(frame: frame, tintColor: tintColor, highlighted: highlighted)
        }
    }
    
    //MARK: - Touch tracking methods
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        becomeFirstResponder()
        handleTouch(touch: touch)
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        handleTouch(touch: touch)
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == self {
            return !isUserInteractionEnabled
        }
        return self.shouldBeginGestureRecognizerBlock != nil ? shouldBeginGestureRecognizerBlock!(gestureRecognizer) : false
    }
    
    func handleTouch(touch: UITouch) {
        let width = bounds.size.width / maximumValue
        let location = touch.location(in: self)
        var value = location.x / width
        
        value = ceil(value)
        
        setRatingValue(value: Int(value))
    }
    
    override var intrinsicContentSize: CGSize {
        let height : CGFloat = 44
        return CGSize(width: maximumValue * height + (maximumValue - 1) * spacing, height: height)
    }

}
