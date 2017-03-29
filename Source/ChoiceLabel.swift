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
    private let titleTextStyle = OEXMutableTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralBlackT())
    private let valueTextStyle = OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().neutralDark())
    
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
        titleStack.alignment = .center
        titleStack.spacing = StandardHorizontalMargin / 2
        titleStack.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        
        let stack = TZStackView(arrangedSubviews: [titleStack, valueLabel])
        stack.alignment = .center
        stack.spacing = StandardHorizontalMargin
        self.addSubview(stack)
        stack.snp_makeConstraints {make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
            make.leading.equalTo(self)
            make.trailing.lessThanOrEqualTo(self)
        }
        
        iconView.contentMode = iconView.isRightToLeft ? .right : .left
        iconView.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        iconView.tintColor = titleTextStyle.color
        iconView.snp_makeConstraints { make in
            make.width.equalTo(type(of: self).minIconSize).priorityMedium()
        }
        iconView.isHidden = true
        
        valueLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: .horizontal)
    }
    
    var titleText : String? {
        didSet {
            self.titleLabel.attributedText = titleTextStyle.attributedString(withText: titleText)
        }
    }
    var valueText: String? {
        didSet {
            self.valueLabel.attributedText = valueTextStyle.attributedString(withText: valueText)
        }
    }
    
    var icon: Icon? {
        didSet {
            iconView.image = icon?.imageWithFontSize(size: type(of: self).iconSize)
            iconView.isHidden = icon == nil
        }
    }
}
