//
//  DropDownCellTableViewCell.swift
//  DropDown
//
//  Created by Kevin Hirsch on 28/07/15.
//  Copyright (c) 2015 Kevin Hirsch. All rights reserved.
//

import UIKit

open class DropDownCell: UITableViewCell {
    
	//UI
    lazy var optionLabel = UILabel()
    
    var optionText: String?
	
	var selectedBackgroundColor: UIColor?
    var normalBackgroundColor: UIColor?
    
    var highlightTextColor: UIColor?
    var normalTextColor: UIColor?
    
    var normalTextStyle: OEXTextStyle?
    var selectedTextStyle: OEXTextStyle?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        addSubview(optionLabel)
        
        optionLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.equalTo(self).inset(StandardVerticalMargin)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
	override open var isSelected: Bool {
		willSet {
			setSelected(newValue, animated: false)
		}
	}
	
	override open var isHighlighted: Bool {
		willSet {
			setSelected(newValue, animated: false)
		}
	}
	
	override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
		setSelected(highlighted, animated: animated)
	}
	
	override open func setSelected(_ selected: Bool, animated: Bool) {
		let executeSelection: () -> Void = { [weak self] in
			guard let `self` = self else { return }

			if let selectedBackgroundColor = self.selectedBackgroundColor,
               let normalBackgroundColor = self.normalBackgroundColor {
				if selected {
					self.backgroundColor = selectedBackgroundColor
                    self.optionLabel.attributedText = self.selectedTextStyle?.attributedString(withText: self.optionText)
				} else {
					self.backgroundColor = normalBackgroundColor
                    self.optionLabel.attributedText = self.normalTextStyle?.attributedString(withText: self.optionText)
				}
			}
		}
        		
		if animated {
			UIView.animate(withDuration: 0.3, animations: {
				executeSelection()
			})
		} else {
			executeSelection()
		}

		accessibilityTraits = selected ? .selected : .none
	}
	
}
