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
    private var paddingHorizontol: CGFloat = 20.0
    private var verticleSpace: CGFloat = 3.0
    private var paddingTop:CGFloat = 0.0
    private var textFieldHeight:CGFloat = 40.0
    private var textViewHeight:CGFloat = 100.0
    private var textInputViewHeight: CGFloat{
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea ? textViewHeight : textFieldHeight
    }
    
    // MARK: - Properties -
    
    let formTitleLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.base, color: OEXStyles.shared().neutralDark())
    let formInstructionLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: OEXStyles.shared().neutralDark())
    let formErrorLabelStyle = OEXTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: UIColor.red)
    
    // MARK: - UI Properties -
    lazy private var lblTextInput: UILabel = {
        let label = UILabel()
        label.applyLabelDefaults()
        label.attributedText = self.formField?.isRequired ?? false ? self.formTitleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "") \(Strings.asteric)") : self.formTitleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "")")
        return label
    }()
    // Used in child class
    lazy var textInputField: RegistrationTextField = {
        let textField = RegistrationTextField()
        textField.defaultTextAttributes = OEXStyles.shared().textFieldBodyStyle.attributes
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
    
    lazy private var lblErrorMessage: UILabel = {
        let label = UILabel()
        label.applyLabelDefaults()
        return label
    }()
    
    lazy private var lblInstructionMessage: UILabel = {
        let label = UILabel()
        label.applyLabelDefaults()
        label.attributedText = self.formInstructionLabelStyle.attributedString(withText: self.formField?.instructions ?? "")
        return label
    }()
    
    private var textInputView: UIView{
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea ? textInputArea : textInputField
    }
    
    
    // Used in child class
    var formField: OEXRegistrationFormField?
    var errorMessage: String? {
        didSet{
            lblErrorMessage.attributedText = self.formErrorLabelStyle.attributedString(withText: errorMessage ?? "")
        }
    }
    
    var currentValue: String? {
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea ? textInputArea.text : textInputField.text
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
        addSubview(lblTextInput)
        addSubview(textInputView)
        addSubview(lblErrorMessage)
        addSubview(lblInstructionMessage)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        // Setup Constraints
        lblTextInput.snp_makeConstraints { (maker) in
            maker.top.equalTo(self).offset(paddingTop)
            maker.leading.equalTo(self).offset(paddingHorizontol)
            maker.trailing.equalTo(self).inset(paddingHorizontol)
            
        }
        
        textInputView.snp_makeConstraints { (maker) in
            maker.leading.equalTo(lblTextInput.snp_leading)
            maker.trailing.equalTo(lblTextInput.snp_trailing)
            maker.top.equalTo(lblTextInput.snp_bottom).offset(verticleSpace)
            maker.height.equalTo(textInputViewHeight)
        }
        
        lblErrorMessage.snp_makeConstraints { (maker) in
            maker.leading.equalTo(lblTextInput.snp_leading)
            maker.trailing.equalTo(lblTextInput.snp_trailing)
            maker.top.equalTo(textInputView.snp_bottom).offset(verticleSpace)
        }
        
        lblInstructionMessage.snp_makeConstraints { (maker) in
            maker.leading.equalTo(lblTextInput.snp_leading)
            maker.trailing.equalTo(lblTextInput.snp_trailing)
            maker.top.equalTo(lblErrorMessage.snp_bottom).offset(verticleSpace)
            maker.bottom.equalTo(snp_bottom).inset(StandardVerticalMargin)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Super View is not constraint base. So need to call sizeToFit on labels to show layout properly. As Superviews height is calculated after randering views.
        lblTextInput.sizeToFit()
        lblErrorMessage.sizeToFit()
        lblInstructionMessage.sizeToFit()
        var height = lblTextInput.frame.size.height + lblErrorMessage.frame.size.height + lblInstructionMessage.frame.size.height + StandardVerticalMargin + (3 * verticleSpace)
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
        if formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea
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



