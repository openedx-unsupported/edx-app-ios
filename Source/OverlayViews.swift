//
//  OverlayViews.swift
//  edX
//
//  Created by Saeed Bashir on 5/13/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class OfflineInfoOverlay : UIView {
    private let titleLabel : UILabel = UILabel()
    private let detailLabel : UILabel = UILabel()
    private var bottomButton : UIButton = UIButton(type: .System)
    
    private var hasBottomButton = false
    
    private var titleStyle : OEXTextStyle  {
        return OEXMutableTextStyle(weight: .SemiBold, size: .Large, color : OEXStyles.sharedStyles().neutralDark())
    }
    
    private var detailStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralDark())
        style.alignment = .Center
        
        return style
    }
    
    private var buttonFontStyle : OEXTextStyle {
        return OEXTextStyle(weight :.Normal, size : .Base, color : OEXStyles.sharedStyles().neutralDark())
    }
    
    var title : String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = newValue.map { detailStyle.attributedStringWithText($0) }
        }
    }
    
    var attributedTitle : NSAttributedString? {
        get {
            return titleLabel.attributedText
        }
        set {
            titleLabel.attributedText = newValue
        }
    }
    
    var detail : String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.attributedText = newValue.map { detailStyle.attributedStringWithText($0) }
        }
    }
    
    var attributedDetail : NSAttributedString? {
        get {
            return detailLabel.attributedText
        }
        set {
            detailLabel.attributedText = newValue
        }
    }
    
    private var buttonTitle : String? {
        get {
            return bottomButton.titleLabel?.text
        }
        set {
            if let title = newValue {
                let attributedTitle = buttonFontStyle.withWeight(.SemiBold).attributedStringWithText(title)
                bottomButton.setAttributedTitle(attributedTitle, forState: .Normal)
                hasBottomButton = true
                setNeedsUpdateConstraints()
            }
            else {
                bottomButton.setAttributedTitle(nil, forState: .Normal)
            }
        }
    }
    
    init(title: String?, detail: String?) {
        super.init(frame: CGRectZero)
        self.backgroundColor = OEXStyles.sharedStyles().warningBase()

        self.detailLabel.numberOfLines = 0
        setupViews(title, detail: detail)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        
        titleLabel.snp_makeConstraints { make in
            make.top.equalTo(self).offset(OEXStatusMessagePadding)
            make.centerX.equalTo(self)
        }
        
        detailLabel.snp_makeConstraints { make in
            if let _ = title {
                make.top.equalTo(titleLabel.snp_bottom).offset(OEXStatusMessagePadding)
            }
            else {
                make.top.equalTo(self).offset(OEXStatusMessagePadding)
            }
            
            make.leading.equalTo(self).offset(OEXStatusMessagePadding)
            make.trailing.equalTo(self).offset(-OEXStatusMessagePadding)
            
            if !hasBottomButton {
                make.bottom.equalTo(self).offset(-OEXStatusMessagePadding)
            }
        }
        
        if hasBottomButton {
            bottomButton.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.detailLabel.snp_bottom).offset(StandardVerticalMargin)
                make.centerX.equalTo(self)
                make.bottom.equalTo(self)
            }
        }
        super.updateConstraints()
    }
    
    private func setupViews(title: String?, detail : String?) {
        
        self.detail = detail
        self.title = title
        
        detailLabel.numberOfLines = 0
        
        bottomButton.contentEdgeInsets = UIEdgeInsets(top: StandardVerticalMargin, left: StandardHorizontalMargin, bottom: 2 * StandardVerticalMargin, right: StandardHorizontalMargin)
        
        addSubview(titleLabel)
        addSubview(detailLabel)
        addSubview(bottomButton)
        
    }
    
    var buttonInfo : MessageButtonInfo? {
        didSet {
            self.bottomButton.oex_removeAllActions()
            self.buttonTitle = buttonInfo?.title
            if let action = buttonInfo?.action {
                self.bottomButton.oex_addAction({button in action() }, forEvents: .TouchUpInside)
            }
        }
    }
}