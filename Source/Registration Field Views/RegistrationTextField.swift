//
//  RegistrationTextField.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 14/11/2017.
//  Copyright © 2017 Muhammad Zeeshan Arif. All rights reserved.
//

import UIKit

class RegistrationTextField: UITextField {
    
    private let padding = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8);
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, padding)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextField()
    }
    
    private func setupTextField() {
        background = #imageLiteral(resourceName: "bt_grey_default.png")
        layer.cornerRadius = 4
        borderStyle = .none
    }
}

