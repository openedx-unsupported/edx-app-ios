//
//  RatingView.swift
//  edX
//
//  Created by Danial Zahid on 1/25/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RatingView: UIControl {

    typealias RatingViewShouldBeginGestureRecognizerBlock = (UIGestureRecognizer) -> Bool
    
    let maximumValue : CGFloat = 5
    let minimumValue : CGFloat = 0
    var value : CGFloat = 0
    let spacing : CGFloat = 5
    
    let emptyImage = Icon.StarEmpty.imageWithFontSize(40.0)
    let filledImage = Icon.StarFilled.imageWithFontSize(40.0)
    
    var shouldBeginGestureRecognizerBlock : RatingViewShouldBeginGestureRecognizerBlock?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //MARK: - Setup methods
    func setupView() {
        backgroundColor = UIColor.whiteColor()
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        setNeedsDisplay()
    }
    
    //MARK: - Action generators
    func setValue(value: CGFloat, sendValueChangedAction sendAction: Bool) {
        willChangeValueForKey("value")
        if self.value != value && value >= minimumValue && value <= maximumValue {
            self.value = value
            if sendAction {
                sendActionsForControlEvents(UIControlEvents.ValueChanged)
            }
            setNeedsDisplay()
        }
        didChangeValueForKey("value")
    }
    
    //MARK: - Draw methods
    func drawImageWithFrame(frame: CGRect, tintColor: UIColor, highlighted: Bool) {
        guard let image : UIImage = highlighted ? filledImage : emptyImage else { return }
        drawImage(image, frame: frame, tintColor: tintColor)
    }
    
    func drawImage(image: UIImage, frame: CGRect, tintColor: UIColor) {
        if image.renderingMode == UIImageRenderingMode.AlwaysTemplate {
            tintColor.setFill()
        }
        image.drawInRect(frame)
    }
    
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context!, backgroundColor?.CGColor ?? UIColor.whiteColor().CGColor)
        CGContextFillRect(context!, rect)
        
        let availableWidth = rect.size.width - (spacing * (maximumValue - 1)) - 2
        let cellWidth = (availableWidth / maximumValue)
        let starSide = (cellWidth <= rect.size.height) ? cellWidth : rect.size.height
        
        for idx in 0 ..< Int(maximumValue) {
            var pointX = (cellWidth * CGFloat(idx)) + (cellWidth / 2)
            pointX += (spacing * CGFloat(idx)) + 1
            let center = CGPointMake(pointX, rect.size.height/2)
            let frame = CGRectMake(center.x - starSide/2, center.y - starSide/2, starSide, starSide)
            let highlighted = (idx + 1 <= Int(ceil(value)))
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
        let cellWidth = bounds.size.width / maximumValue
        let location = touch.locationInView(self)
        var value = location.x / cellWidth
        
        value = ceil(value)
        
        setValue(value, sendValueChangedAction: true)
    }
    
    //MARK: - Override behavorial methods
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func intrinsicContentSize() -> CGSize {
        let height : CGFloat = 44
        return CGSizeMake(maximumValue * height + (maximumValue - 1) * spacing, height)
    }

}
