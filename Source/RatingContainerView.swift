//
//  RatingContainerView.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol RatingContainerDelegate {
    func didSubmitRating(rating: Int)
    func closeButtonPressed()
}

class RatingContainerView: UIView {

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXStylesProvider>
    
    let environment : Environment
    private let viewHorizontalMargin = 50
    
    private let contentView = UIView()
    private let descriptionLabel = UILabel()
    private let ratingView = RatingView()
    private let closeButton = UIButton()
    private let submitButton = UIButton()
    var delegate : RatingContainerDelegate?
    
    private var standardTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: environment.styles.neutralXDark())
        style.alignment = NSTextAlignment.Center
        descriptionLabel.lineBreakMode = .ByWordWrapping
        return style
    }
    
    private var disabledButtonStyle : ButtonStyle {
        return ButtonStyle(textStyle: OEXTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: environment.styles.neutralWhite()), backgroundColor: environment.styles.neutralBase(), borderStyle: BorderStyle(cornerRadius: .Size(0), width: .Size(0), color: nil), contentInsets: nil, shadow: nil)
    }
    
    private var enabledButtonStyle : ButtonStyle {
        return ButtonStyle(textStyle: OEXTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: environment.styles.neutralWhite()), backgroundColor: environment.styles.primaryBaseColor(), borderStyle: BorderStyle(cornerRadius: .Size(0), width: .Size(0), color: nil), contentInsets: nil, shadow: nil)
    }
    
    private var closeButtonTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XLarge, color: environment.styles.neutralDark())
    }
    
    init(environment : Environment) {
        self.environment = environment
        super.init(frame: CGRectZero)
        
        //Setup view properties
        contentView.applyStandardContainerViewStyle()
        self.applyStandardContainerViewShadow()
        
        //Setup label properties
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = standardTextStyle.attributedStringWithText(Strings.AppReview.rateTheAppQuestion)
        
        //Setup Submit button
        toggleSubmitButton(false)
        submitButton.oex_addAction({[weak self] (action) in
            self?.delegate?.didSubmitRating(self!.ratingView.value)
            }, forEvents: UIControlEvents.TouchUpInside)
        
        //Setup close button
        closeButton.layer.cornerRadius = 15
        closeButton.layer.borderColor = environment.styles.neutralDark().CGColor
        closeButton.layer.borderWidth = 1.0
        closeButton.layer.masksToBounds = true
        closeButton.setAttributedTitle(Icon.Close.attributedTextWithStyle(closeButtonTextStyle), forState: UIControlState.Normal)
        closeButton.backgroundColor = UIColor.whiteColor()
        closeButton.oex_addAction({[weak self] (action) in
            self?.delegate?.closeButtonPressed()
            }, forEvents: UIControlEvents.TouchUpInside)
        
        //Setup ratingView action
        ratingView.oex_addAction({[weak self] (action) in
            self?.toggleSubmitButton(self?.ratingView.value > 0)
            }, forEvents: UIControlEvents.ValueChanged)
        
        addSubview(contentView)
        addSubview(closeButton)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(ratingView)
        contentView.addSubview(submitButton)
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupConstraints() {
        
        contentView.snp_remakeConstraints { (make) in
            make.edges.equalTo(snp_edges)
        }
        
        descriptionLabel.snp_remakeConstraints { (make) in
            make.top.equalTo(contentView.snp_top).offset(30)
            make.left.equalTo(contentView.snp_left).offset(viewHorizontalMargin)
            make.right.equalTo(contentView.snp_right).inset(viewHorizontalMargin)
        }
        
        ratingView.snp_remakeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp_bottom).offset(StandardVerticalMargin*2)
            make.left.greaterThanOrEqualTo(contentView.snp_left).offset(viewHorizontalMargin)
            make.right.greaterThanOrEqualTo(contentView.snp_right).inset(viewHorizontalMargin)
            make.centerX.equalTo(contentView.snp_centerX)
        }
        
        submitButton.snp_remakeConstraints { (make) in
            make.left.equalTo(contentView.snp_left)
            make.right.equalTo(contentView.snp_right)
            make.bottom.equalTo(contentView.snp_bottom)
            make.height.equalTo(40)
            make.top.equalTo(ratingView.snp_bottom).offset(StandardVerticalMargin*2)
        }
        
        closeButton.snp_remakeConstraints { (make) in
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.right.equalTo(contentView.snp_right).offset(8)
            make.top.equalTo(contentView.snp_top).offset(-StandardVerticalMargin)
            
        }
    }
    
    private func toggleSubmitButton(enabled: Bool) {
        let style = enabled ? enabledButtonStyle : disabledButtonStyle
        submitButton.applyButtonStyle(style, withTitle: Strings.AppReview.submit)
        submitButton.userInteractionEnabled = enabled
    }
    
    func setRating(rating: Int) {
        ratingView.setRatingValue(rating)
    }
}
