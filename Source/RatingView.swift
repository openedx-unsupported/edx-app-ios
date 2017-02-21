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
    
    let emptyImage = Icon.StarEmpty.imageWithFontSize(imageSize)
    let filledImage = Icon.StarFilled.imageWithFontSize(imageSize)
    
    var shouldBeginGestureRecognizerBlock : RatingViewShouldBeginGestureRecognizerBlock?
    
    //MARK: - Action generators
    func setRatingValue(value: Int) {
        willChangeValueForKey("value")
        if self.value != value && value >= Int(minimumValue) && value <= Int(maximumValue) {
            self.value = value
            sendActionsForControlEvents(UIControlEvents.ValueChanged)
            setNeedsDisplay()
        }
        didChangeValueForKey("value")
    }
    
    //MARK: - Draw methods
    private func drawImageWithFrame(frame: CGRect, tintColor: UIColor, highlighted: Bool) {
        guard let image : UIImage = highlighted ? filledImage : emptyImage else { return }
        drawImage(image, frame: frame, tintColor: tintColor)
    }
    
    private func drawImage(image: UIImage, frame: CGRect, tintColor: UIColor) {
        if image.renderingMode == UIImageRenderingMode.AlwaysTemplate {
            tintColor.setFill()
        }
        image.drawInRect(frame)
    }
    
    override func drawRect(rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            CGContextSetFillColorWithColor(context, backgroundColor?.CGColor ?? UIColor.whiteColor().CGColor)
            CGContextFillRect(context, rect)
        }
        
        let availableWidth = rect.size.width - (spacing * (maximumValue - 1)) - 2
        let cellWidth = (availableWidth / maximumValue)
        let starSide = (cellWidth <= rect.size.height) ? cellWidth : rect.size.height
        
        for idx in 0 ..< Int(maximumValue) {
            var pointX = (cellWidth * CGFloat(idx)) + (cellWidth / 2)
            pointX += (spacing * CGFloat(idx)) + 1
            let center = CGPointMake(pointX, rect.size.height/2)
            let frame = CGRectMake(center.x - starSide/2, center.y - starSide/2, starSide, starSide)
            let highlighted = (idx + 1 <= value)
            drawImageWithFrame(frame, tintColor: tintColor, highlighted: highlighted)
        }
    }
    
    //MARK: - Touch tracking methods
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.beginTrackingWithTouch(touch, withEvent: event)
        becomeFirstResponder()
        handleTouch(touch)
        return true
    }
    
    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        super.continueTrackingWithTouch(touch, withEvent: event)
        handleTouch(touch)
        return true
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == self {
            return !userInteractionEnabled
        }
        return self.shouldBeginGestureRecognizerBlock != nil ? shouldBeginGestureRecognizerBlock!(gestureRecognizer) : false
    }
    
    func handleTouch(touch: UITouch) {
        let width = bounds.size.width / maximumValue
        let location = touch.locationInView(self)
        var value = location.x / width
        
        value = ceil(value)
        
        setRatingValue(Int(value))
    }
    
    override func intrinsicContentSize() -> CGSize {
        let height : CGFloat = 44
        return CGSizeMake(maximumValue * height + (maximumValue - 1) * spacing, height)
    }

}
