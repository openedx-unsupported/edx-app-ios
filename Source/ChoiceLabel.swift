//
//  ChoiceLabel.swift
//  edX
//
//  Created by Akiva Leffert on 12/4/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class ChoiceLabel : UIView {
    private static let iconSize : CGFloat = 20
    // Want all icons to take up the same amount of space (including padding)
    // So add a little extra space to account for wide icons
    private static let minIconSize : CGFloat = iconSize + 6
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let titleTextStyle = OEXMutableTextStyle(weight: .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralBlackT())
    private let valueTextStyle = OEXTextStyle(weight: .Normal, size: .Large, color: OEXStyles.sharedStyles().neutralDark())
    
    override init(frame : CGRect) {
        super.init(frame : frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        let titleStack = TZStackView(arrangedSubviews: [iconView, titleLabel])
        titleStack.alignment = .Center
        titleStack.spacing = StandardHorizontalMargin / 2
        titleStack.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        
        let stack = TZStackView(arrangedSubviews: [titleStack, valueLabel])
        stack.alignment = .Center
        stack.spacing = StandardHorizontalMargin
        self.addSubview(stack)
        stack.snp_makeConstraints {make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
            make.leading.equalTo(self)
            make.trailing.lessThanOrEqualTo(self)
        }
        
        iconView.contentMode = iconView.isRightToLeft ? .Right : .Left
        iconView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        iconView.tintColor = titleTextStyle.color
        iconView.snp_makeConstraints { make in
            make.width.equalTo(self.dynamicType.minIconSize).priorityMedium()
        }
        iconView.hidden = true
        
        valueLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
    }
    
    var titleText : String? {
        didSet {
            self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(titleText)
        }
    }
    var valueText: String? {
        didSet {
            self.valueLabel.attributedText = valueTextStyle.attributedStringWithText(valueText)
        }
    }
    
    var icon: Icon? {
        didSet {
            iconView.image = icon?.imageWithFontSize(self.dynamicType.iconSize)
            iconView.hidden = icon == nil
        }
    }
}
