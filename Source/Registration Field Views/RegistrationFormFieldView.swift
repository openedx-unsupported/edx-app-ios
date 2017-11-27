//
//  RegistrationFormFieldView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 22/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RegistrationFormFieldView: UIView, UITextFieldDelegate {
    
    // MARK: - Configurations -
    
    fileprivate var paddingHorizontol: CGFloat = 20.0
    fileprivate var verticleSpace: CGFloat = 3.0
    fileprivate var width:CGFloat = 0.0
    fileprivate var paddingTop:CGFloat = 0.0
    fileprivate var paddingBottom: CGFloat = 10.0
    fileprivate var offset:CGFloat = 0.0
    
    let formFieldStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.base, color: OEXStyles.shared().neutralDark())
    let formFieldInstructionsStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: OEXStyles.shared().neutralDark())
    
    // MARK: - Properties -
    
    lazy var lblTextInput: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        return label
    }()
    lazy var textInputField: RegistrationTextField = {
        let textField = RegistrationTextField()
        textField.font = OEXStyles.shared().sansSerif(ofSize: 13.0)
        textField.textColor = UIColor(colorLiteralRed: 0.275, green: 0.29, blue: 0.314, alpha: 1.0)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    lazy var textInputArea: OEXPlaceholderTextView = {
        let textArea = OEXPlaceholderTextView()
        textArea.textContainer.lineFragmentPadding = 0.0
        textArea.textContainerInset = UIEdgeInsetsMake(5, 10, 5, 10)
        textArea.font = OEXStyles.shared().sansSerif(ofSize: 13.0)
        textArea.textColor = UIColor(colorLiteralRed: 0.275, green: 0.29, blue: 0.314, alpha: 0.9)
        textArea.placeholderTextColor = UIColor(colorLiteralRed: 0.675, green: 0.69, blue: 0.614, alpha: 0.9)
        textArea.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        textArea.layer.borderWidth = 1.0
        textArea.autocapitalizationType = .none
        textArea.layer.cornerRadius = 5.0
        textArea.clipsToBounds = true
        return textArea
    }()
    
    lazy var lblErrorMessage: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = OEXStyles.shared().sansSerif(ofSize: 10.0)
        label.textColor = UIColor.red
        return label
    }()
    
    lazy var lblInstructionMessage: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    var formField: OEXRegistrationFormField?
    var _errorMessage: String = ""
    var errorMessage: String{
        get{
            return _errorMessage
        }
        set{
            _errorMessage = newValue
            lblErrorMessage.text = _errorMessage
            self.lblErrorMessage.sizeToFit()
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }
    
    var currentValue: String {
        if let formField = formField{
            if formField.fieldType == OEXRegistrationFieldTypeTextArea
            {
                return self.textInputArea.text!
            }
            else{
                return self.textInputField.text!
            }
        }
        return ""
    }
    
    // MARK: - Setup View -
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(with formField: OEXRegistrationFormField){
        self.init(frame: CGRect.zero)
        self.formField = formField
        load()
    }
    
    func load() {
        if let formField = formField{
            width = UIScreen.main.bounds.width - (paddingHorizontol * 2)
            offset = paddingTop
            
            self.autoresizingMask = [.flexibleHeight , .flexibleWidth]
            // Add subviews
            self.addSubview(lblTextInput)
            
            if formField.fieldType == OEXRegistrationFieldTypeTextArea
            {
                self.addSubview(textInputArea)
            }
            else{
                self.addSubview(textInputField)
                textInputField.delegate = self
            }
            
            self.addSubview(lblErrorMessage)
            self.addSubview(lblInstructionMessage)
            
            if formField.isRequired{
                self.lblTextInput.attributedText = self.formFieldStyle.attributedString(withText: "\(formField.label) \(Strings.asteric)")
            }
            else{
                self.lblTextInput.attributedText = self.formFieldStyle.attributedString(withText: formField.label)
            }
            
            if formField.fieldType == OEXRegistrationFieldTypeTextArea
            {
                self.textInputArea.accessibilityHint = formField.instructions
            }
            else{
                self.textInputField.accessibilityHint = formField.instructions
            }
            
            
            self.lblErrorMessage.text = _errorMessage
            self.lblInstructionMessage.attributedText = self.formFieldInstructionsStyle.attributedString(withText: formField.instructions)
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.layoutSubviews()
        }
    }
    
   
    
    override func layoutSubviews() {
        if let formField = formField{
            
            offset = paddingTop
            self.lblTextInput.frame = CGRect(x: paddingHorizontol, y: offset, width: width, height: 21)
            offset += 21 + verticleSpace
            
            
            if formField.fieldType == OEXRegistrationFieldTypeTextArea
            {
                self.textInputArea.frame = CGRect(x: paddingHorizontol, y: offset, width: width, height: 100)
                offset += 100
            }
            else{
                self.textInputField.frame = CGRect(x: paddingHorizontol, y: offset, width: width, height: 40)
                offset += 40
            }
            
            
            var possibleErrorLabelHeight:CGFloat = 0.0
            if self.lblErrorMessage.text != "" {
                possibleErrorLabelHeight = self.errorMessage.height(withConstrainedWidth: width, font: lblErrorMessage.font)
                offset += verticleSpace
            }
            self.lblErrorMessage.frame = CGRect(x: paddingHorizontol, y: offset, width: width, height: possibleErrorLabelHeight)
            offset += possibleErrorLabelHeight
            var possibleInstructionLabelHeight:CGFloat = 0.0
            if self.lblInstructionMessage.text != "" {
                possibleInstructionLabelHeight = formField.instructions.height(withConstrainedWidth: width, font: lblInstructionMessage.font)
                offset += verticleSpace
            }
            
            self.lblInstructionMessage.frame = CGRect(x: paddingHorizontol, y: offset, width: width, height: possibleInstructionLabelHeight)
            offset += possibleInstructionLabelHeight + paddingBottom
            var frame = self.frame
            frame.size.height = offset
            self.frame = frame
        }
        self.lblTextInput.sizeToFit()
        self.lblErrorMessage.sizeToFit()
        self.lblInstructionMessage.sizeToFit()
        super.layoutSubviews()
    }
    
    func takeValue(_ value: String) {
        if let formField = formField{
            if formField.fieldType == OEXRegistrationFieldTypeTextArea
            {
                self.textInputArea.text = value
            }
            else{
                self.textInputField.text = value
            }
        }
    }
    
    
    func clearError() {
        errorMessage = ""
    }
    
}
extension String{
    fileprivate func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return ceil(boundingBox.height)
    }
}
