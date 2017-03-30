//
//  ProfileImageView.swift
//  edX
//
//  Created by Michael Katz on 9/17/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@IBDesignable
class ProfileImageView: UIImageView {
    
    var borderWidth: CGFloat = 1.0
    var borderColor: UIColor?

    private func setup() {
        var borderStyle = OEXStyles.shared().profileImageViewBorder(width: borderWidth)
        if borderColor != nil {
            borderStyle = BorderStyle(cornerRadius: borderStyle.cornerRadius, width: borderStyle.width, color: borderColor)
        }
        applyBorderStyle(style: borderStyle)
        backgroundColor = OEXStyles.shared().profileImageBorderColor()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override init (frame: CGRect) {
        super.init(frame: frame)
        let bundle = Bundle(for: type(of: self))
        image = UIImage(named: "profilePhotoPlaceholder", in: bundle, compatibleWith: self.traitCollection)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
        let bundle = Bundle(for: type(of: self))
        image = UIImage(named: "profilePhotoPlaceholder", in: bundle, compatibleWith: self.traitCollection)
    }
    
    func blurimate() -> Removable {
        let blur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blur)

        let vib = UIVibrancyEffect(blurEffect: blur)
        let vibView = UIVisualEffectView(effect: vib)
        let spinner = SpinnerView(size: .Medium, color: .White)
        vibView.contentView.addSubview(spinner)
        spinner.snp_makeConstraints {make in
            make.center.equalTo(spinner.superview!)
        }
        
        spinner.startAnimating()
        
        insertSubview(blurView, at: 0)
        blurView.contentView.addSubview(vibView)
        vibView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(vibView.superview!)
        }
        blurView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        
        return BlockRemovable() {
            UIView.animate(withDuration: 0.4, animations: {
                spinner.stopAnimating()
                }) { _ in
                    blurView.removeFromSuperview()
            }
        }
    }
}
