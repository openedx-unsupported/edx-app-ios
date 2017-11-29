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
    private var textFieldHeight:CGFloat = 40.0
    private var textViewHeight:CGFloat = 100.0
    private var textInputViewHeight: CGFloat{
        return isTextArea ? textViewHeight : textFieldHeight
    }
    
    // MARK: - Properties -
    
    let titleLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.base, color: OEXStyles.shared().neutralDark())
    let instructionsLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: OEXStyles.shared().neutralDark())
    let errorLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: UIColor.red)
    
    // MARK: - UI Properties -
    lazy private var textInputLabel: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedText = self.formField?.isRequired ?? false ? self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "") \(Strings.asteric)") : self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "")")
        return label
    }()
    // Used in child class
    lazy var textInputField: RegistrationTextField = {
        let textField = RegistrationTextField()
        textField.defaultTextAttributes = OEXStyles.shared().textFieldStyle(with: .base).attributes
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    lazy private var textInputArea: OEXPlaceholderTextView = {
        let textArea = OEXPlaceholderTextView()
        textArea.textContainer.lineFragmentPadding = 0.0
        textArea.autocapitalizationType = .none
        textArea.applyBorderStyle()
        return textArea
    }()
    
    lazy private var errorLabel: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    lazy private var lblInstructionMessage: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.attributedText = self.instructionsLabelStyle.attributedString(withText: self.formField?.instructions ?? "")
        return label
    }()
    
    private var textInputView: UIView{
        return isTextArea ? textInputArea : textInputField
    }
    
    
    // Used in child class
    private(set) var formField: OEXRegistrationFormField?
    var errorMessage: String? {
        didSet{
            errorLabel.attributedText = self.errorLabelStyle.attributedString(withText: errorMessage ?? "")
        }
    }
    
    var currentValue: String? {
        return isTextArea ? textInputArea.text : textInputField.text
    }
    
    var isTextArea: Bool{
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea
    }
    
    // MARK: - Setup View -
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(with formField: OEXRegistrationFormField){
        super.init(frame: CGRect.zero)
        self.formField = formField
        load()
    }
    
    // public function as can be inherited
    func load() {
        guard let formField = formField else { return }
        addSubViews()
        textInputView.accessibilityLabel = formField.label
        textInputView.accessibilityHint = formField.isRequired ? "\(Strings.Accessibility.requiredInput),\(formField.instructions)" : "\(Strings.Accessibility.optionalInput),\(formField.instructions)"
    }
    
    func addSubViews(){
        // Add subviews
        addSubview(textInputLabel)
        addSubview(textInputView)
        addSubview(errorLabel)
        addSubview(lblInstructionMessage)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        // Setup Constraints
        textInputLabel.snp_makeConstraints { (maker) in
            maker.top.equalTo(self)
            maker.leading.equalTo(self).offset(StandardHorizontalMargin)
            maker.trailing.equalTo(self).inset(StandardHorizontalMargin)
            
        }
        
        textInputView.snp_makeConstraints { (maker) in
            maker.leading.equalTo(textInputLabel.snp_leading)
            maker.trailing.equalTo(textInputLabel.snp_trailing)
            maker.top.equalTo(textInputLabel.snp_bottom).offset(StandardVerticalMargin/2.0)
            maker.height.equalTo(textInputViewHeight)
        }
        
        errorLabel.snp_makeConstraints { (maker) in
            maker.leading.equalTo(textInputLabel.snp_leading)
            maker.trailing.equalTo(textInputLabel.snp_trailing)
            maker.top.equalTo(textInputView.snp_bottom).offset(StandardVerticalMargin/2.0)
        }
        
        lblInstructionMessage.snp_makeConstraints { (maker) in
            maker.leading.equalTo(textInputLabel.snp_leading)
            maker.trailing.equalTo(textInputLabel.snp_trailing)
            maker.top.equalTo(errorLabel.snp_bottom).offset(StandardVerticalMargin/2.0)
            maker.bottom.equalTo(snp_bottom).inset(StandardVerticalMargin)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Super View is not constraint base. So need to call sizeToFit on labels to show layout properly. As Superviews height is calculated after randering views.
        textInputLabel.sizeToFit()
        errorLabel.sizeToFit()
        lblInstructionMessage.sizeToFit()
        var height = textInputLabel.frame.size.height + errorLabel.frame.size.height + lblInstructionMessage.frame.size.height + StandardVerticalMargin + (3.0 * StandardVerticalMargin/2.0)
        if let formField = formField{
            if formField.fieldType == OEXRegistrationFieldTypeTextArea{
                height += textViewHeight
            }
            else{
                height += textFieldHeight
            }
        }
        
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func takeValue(_ value: String) {
        if isTextArea
        {
            textInputArea.text = value
        }
        else{
            textInputField.text = value
        }
    }
    
    
    func clearError() {
        errorMessage = nil
    }
    
    
}



