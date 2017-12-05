//
//  RegistrationFormFieldView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 22/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RegistrationFormFieldView: UIView {
    
    // MARK: - Configurations -
    private var textFieldHeight:CGFloat = 40.0
    private var textViewHeight:CGFloat = 100.0
    private var textInputViewHeight: CGFloat{
        return isTextArea ? textViewHeight : textFieldHeight
    }
    
    // MARK: - Properties -
    let titleLabelStyle = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.base, color: OEXStyles.shared().neutralDark())
    let instructionsLabelStyle = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: OEXStyles.shared().neutralDark())
    let errorLabelStyle = OEXMutableTextStyle(weight: OEXTextWeight.normal, size: OEXTextSize.xxSmall, color: UIColor.red)
    
    // MARK: - UI Properties -
    lazy private var textInputLabel: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.attributedText = self.isRequired ? self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "") \(Strings.asteric)") : self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "")")
        return label
    }()
    
    // Used in child class
    lazy var textInputField: RegistrationTextField = {
        let textField = RegistrationTextField()
        textField.defaultTextAttributes = OEXStyles.shared().textFieldStyle(with: .base).attributes
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(RegistrationFormFieldView.valueDidChange), for: .editingChanged)
        return textField
    }()
    
    lazy private var textInputArea: OEXPlaceholderTextView = {
        let textArea = OEXPlaceholderTextView()
        textArea.textContainer.lineFragmentPadding = 0.0
        textArea.autocapitalizationType = .none
        textArea.applyBorderStyle()
        textArea.delegate = self
        return textArea
    }()
    
    lazy private var errorLabel: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        return label
    }()
    
    lazy private var instructionsLabel: UILabel = {
        let label = UILabel()
        label.isAccessibilityElement = false
        label.numberOfLines = 0
        label.attributedText = self.instructionsLabelStyle.attributedString(withText: self.formField?.instructions ?? "")
        return label
    }()
    
    var textInputView: UIView{
        return isTextArea ? textInputArea : textInputField
    }
    
    // Used in child class
    private(set) var formField: OEXRegistrationFormField?
    var errorMessage: String? {
        didSet{
            errorLabel.attributedText = self.errorLabelStyle.attributedString(withText: errorMessage ?? "")
            refreshAccessibilty()
        }
    }
    
    var currentValue: String {
        let value = isTextArea ? textInputArea.text : textInputField.text
        return value?.trimmingCharacters(in: NSCharacterSet.whitespaces) ?? ""
    }
    
    var isTextArea: Bool{
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea
    }
    
    var isRequired: Bool{
        return formField?.isRequired ?? false
    }
    var hasValue: Bool{
        return currentValue != ""
    }
    
    var isValidInput: Bool{
        guard let errorMessage = validate() else {
            return true
        }
        self.errorMessage = errorMessage
        return false
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
    
    // public method, can be inherited
    func load() {
        titleLabelStyle.lineBreakMode = .byWordWrapping
        instructionsLabelStyle.lineBreakMode = .byWordWrapping
        errorLabelStyle.lineBreakMode = .byWordWrapping
        addSubViews()
        refreshAccessibilty()
    }
    
    func refreshAccessibilty()  {
        guard let formField = formField else { return }
        let errorAccessibility = errorMessage ?? "" != "" ? ",\(Strings.Accessibility.errorText), \(errorMessage ?? "")" : ""
        let requiredOrOptionalAccessibility = isRequired ? Strings.Accessibility.requiredInput : Strings.Accessibility.optionalInput
        textInputView.accessibilityLabel = formField.label
        textInputView.accessibilityHint = "\(requiredOrOptionalAccessibility),\(formField.instructions)\(errorAccessibility)"
    }
    
    func addSubViews(){
        // Add subviews
        addSubview(textInputLabel)
        addSubview(textInputView)
        addSubview(errorLabel)
        addSubview(instructionsLabel)
        setupConstraints()
    }
    
    func setupConstraints() {
        // Setup Constraints
        textInputLabel.snp_makeConstraints { (make) in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        textInputView.snp_makeConstraints { (make) in
            make.leading.equalTo(textInputLabel.snp_leading)
            make.trailing.equalTo(textInputLabel.snp_trailing)
            make.top.equalTo(textInputLabel.snp_bottom).offset(StandardVerticalMargin/2.0)
            make.height.equalTo(textInputViewHeight)
        }
        errorLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(textInputLabel.snp_leading)
            make.trailing.equalTo(textInputLabel.snp_trailing)
            make.top.equalTo(textInputView.snp_bottom).offset(StandardVerticalMargin/2.0)
        }
        instructionsLabel.snp_makeConstraints { (make) in
            make.leading.equalTo(textInputLabel.snp_leading)
            make.trailing.equalTo(textInputLabel.snp_trailing)
            make.top.equalTo(errorLabel.snp_bottom).offset(StandardVerticalMargin/2.0)
            make.bottom.equalTo(snp_bottom).inset(StandardVerticalMargin)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Super View is not constraint base. Calculating superview height.
        let textInputLabelHeight = textInputLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let errorLabelHeight = errorLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let instructionLabelHeight = instructionsLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        var height = textInputLabelHeight + errorLabelHeight + instructionLabelHeight + StandardVerticalMargin + (3.0 * StandardVerticalMargin/2.0)
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
        if isTextArea {
            textInputArea.text = value
        }
        else {
            textInputField.text = value
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    @objc func valueDidChange(){
        errorMessage = validate()
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_FORM_FIELD_VALUE_DID_CHANGE)))
    }
    
    func validate() -> String?{
        guard let field = formField else {
            return nil
        }
        if isRequired && currentValue == "" {
            return field.errorMessage.required == "" ? Strings.registrationFieldEmptyError(fieldName: field.label) : field.errorMessage.required
        }
        let length = currentValue.characters.count
        if length < field.restriction.minLength {
            return field.errorMessage.minLength == "" ? Strings.registrationFieldMinLengthError(fieldName: field.label, count: "\(field.restriction.minLength)")(field.restriction.minLength) : field.errorMessage.minLength
        }
        if length > field.restriction.maxLength && field.restriction.maxLength != 0{
            return field.errorMessage.maxLength == "" ? Strings.registrationFieldMaxLengthError(fieldName: field.label, count: "\(field.restriction.maxLength)")(field.restriction.maxLength): field.errorMessage.maxLength
        }
        
        switch field.fieldType {
        case OEXRegistrationFieldTypeEmail:
            if hasValue && !currentValue.isValidEmailAddress(){
                return Strings.ErrorMessage.invalidEmailFormat
            }
            break
        default:
            break
        }
        return nil
    }
}

extension RegistrationFormFieldView: UITextViewDelegate{
    func textViewDidChange(_ textView: UITextView) {
        valueDidChange()
    }
}

