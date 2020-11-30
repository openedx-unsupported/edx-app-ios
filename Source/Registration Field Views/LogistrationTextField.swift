//
//  LogistrationTextField.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 14/11/2017.
//  Copyright © 2017 Muhammad Zeeshan Arif. All rights reserved.
//

import UIKit

@objc class LogistrationTextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8);
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextField()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextField()
    }
    
    private func setupTextField() {
        backgroundColor = .clear
        layer.borderWidth = 1.0
        layer.borderColor = OEXStyles.shared().neutralBase().cgColor
        layer.cornerRadius = 0.0
        layer.masksToBounds = true
    }
}

