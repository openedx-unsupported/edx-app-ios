//
//  RatingContainerView.swift
//  edX
//
//  Created by Danial Zahid on 1/23/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol RatingContainerDelegate {
    func didSelectRating(rating: CGFloat)
    func closeButtonPressed()
}

class RatingContainerView: UIView {

    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, OEXStylesProvider>
    
    let environment : Environment
    
    let descriptionLabel = UILabel()
    let ratingView = RatingView()
    let closeButton = UIButton()
    var delegate : RatingContainerDelegate?
    
    private var standardTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(weight: OEXTextWeight.SemiBold, size: .Base, color: environment.styles.neutralXDark())
        style.alignment = NSTextAlignment.Center
        descriptionLabel.lineBreakMode = .ByWordWrapping
        return style
    }
    
    init(environment : Environment) {
        self.environment = environment
        super.init(frame: CGRectZero)
        
        //Setup view properties
        backgroundColor = UIColor.whiteColor()
        layer.cornerRadius = 10
        layer.shadowColor = environment.styles.neutralBlack().CGColor;
        layer.shadowRadius = 1.0;
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowOpacity = 0.8;
        
        //Setup label properties
        descriptionLabel.numberOfLines = 0
        descriptionLabel.attributedText = standardTextStyle.attributedStringWithText("How would you rate the edX app?")
        
        //Setup close button
        closeButton.layer.cornerRadius = 15
        closeButton.layer.borderColor = environment.styles.neutralDark().CGColor
        closeButton.layer.borderWidth = 1.0
        closeButton.layer.masksToBounds = true
        closeButton.setImage(UIImage(named: "ic_cancel.png"), forState: UIControlState.Normal)
        closeButton.backgroundColor = UIColor.whiteColor()
        closeButton.oex_addAction({ (action) in
            self.delegate?.closeButtonPressed()
            }, forEvents: UIControlEvents.TouchUpInside)
        
        //Setup ratingView action
        ratingView.oex_addAction({ (action) in
            self.delegate?.didSelectRating(ratingView.value)
            }, forEvents: UIControlEvents.ValueChanged)
        
        addSubview(descriptionLabel)
        addSubview(ratingView)
        addSubview(closeButton)
        
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupConstraints() {
        descriptionLabel.snp_remakeConstraints { (make) in
            make.top.equalTo(self.snp_top).offset(30)
            make.left.equalTo(self.snp_left).offset(50)
            make.right.equalTo(self.snp_right).inset(50)
        }
        
        ratingView.snp_remakeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp_bottom).offset(15)
            make.left.greaterThanOrEqualTo(self.snp_left).offset(50)
            make.right.greaterThanOrEqualTo(self.snp_right).inset(50)
            make.centerX.equalTo(self.snp_centerX)
            make.bottom.equalTo(self.snp_bottom).inset(30)
        }
        
        closeButton.snp_remakeConstraints { (make) in
            make.height.equalTo(30)
            make.width.equalTo(30)
            make.right.equalTo(self.snp_right).offset(8)
            make.top.equalTo(self.snp_top).offset(-8)
        }
    }
}
