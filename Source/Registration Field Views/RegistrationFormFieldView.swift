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
    private var textInputViewHeight: CGFloat {
        return isInputTypeTextArea ? textViewHeight : textFieldHeight
    }
    
    // MARK: - Properties -
    let titleLabelStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    let instructionsLabelStyle = OEXMutableTextStyle(weight: .normal, size: .xxSmall, color: OEXStyles.shared().neutralDark())
    let errorLabelStyle = OEXMutableTextStyle(weight: .normal, size: .xxSmall, color: OEXStyles.shared().errorLight())
    
    
    private var accessibilityIdPrefix: String {
        return "RegistrationFormFieldView:\(formField?.name ?? "")"
    }
    
    // MARK: - UI Properties -
    lazy private var textInputLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        label.attributedText = self.isRequired ? self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "") \(Strings.asteric)") : self.titleLabelStyle.attributedString(withText: "\(self.formField?.label ?? "")")
        label.accessibilityIdentifier = "\(self.accessibilityIdPrefix)-text-input-label"
        return label
    }()
    
    // Used in child class
    lazy var textInputField: RegistrationTextField = {
        let textField = RegistrationTextField()
        textField.defaultTextAttributes = OEXStyles.shared().textFieldStyle(with: .base).attributes
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(RegistrationFormFieldView.valueDidChange), for: .editingChanged)
        textField.accessibilityIdentifier = "\(self.accessibilityIdPrefix)-text-input-field"
        return textField
    }()
    
    lazy private var textInputArea: OEXPlaceholderTextView = {
        let textArea = OEXPlaceholderTextView()
        textArea.textContainer.lineFragmentPadding = 0.0
        textArea.autocapitalizationType = .none
        textArea.applyStandardBorderStyle()
        textArea.delegate = self
        textArea.accessibilityIdentifier = "\(self.accessibilityIdPrefix)-text-input-area"
        return textArea
    }()
    
    lazy private var errorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        label.accessibilityIdentifier = "\(self.accessibilityIdPrefix)-error-label"
        return label
    }()
    
    lazy private var instructionsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        label.attributedText = self.instructionsLabelStyle.attributedString(withText: self.formField?.instructions ?? "")
        label.accessibilityIdentifier = "\(self.accessibilityIdPrefix)-instructions-label"
        return label
    }()
    
    var textInputView: UIView {
        return isInputTypeTextArea ? textInputArea : textInputField
    }
    
    // Used in child class
    private(set) var formField: OEXRegistrationFormField?
    var errorMessage: String? {
        didSet {
            errorLabel.attributedText = self.errorLabelStyle.attributedString(withText: errorMessage ?? "")
            refreshAccessibilty()
        }
    }
    
    var currentValue: String {
        let value = isInputTypeTextArea ? textInputArea.text : textInputField.text
        return value?.trimmingCharacters(in: NSCharacterSet.whitespaces) ?? ""
    }
    
    var isInputTypeTextArea: Bool {
        return formField?.fieldType ?? OEXRegistrationFieldTypeText == OEXRegistrationFieldTypeTextArea
    }
    
    var isRequired: Bool {
        return formField?.isRequired ?? false
    }
    var hasValue: Bool {
        return currentValue != ""
    }
    
    var isValidInput: Bool {
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
    
    init(with formField: OEXRegistrationFormField) {
        super.init(frame: CGRect.zero)
        self.formField = formField
        loadView()
    }
    
    // public method, can be inherited
    func loadView() {
        titleLabelStyle.lineBreakMode = .byWordWrapping
        instructionsLabelStyle.lineBreakMode = .byWordWrapping
        errorLabelStyle.lineBreakMode = .byWordWrapping
        addSubViews()
        refreshAccessibilty()
    }
    
    func refreshAccessibilty() {
        guard let formField = formField else { return }
        let errorAccessibility = errorMessage ?? "" != "" ? ",\(Strings.Accessibility.errorText), \(errorMessage ?? "")" : ""
        let requiredOrOptionalAccessibility = isRequired ? Strings.Accessibility.requiredInput : Strings.Accessibility.optionalInput
        textInputView.accessibilityLabel = formField.label
        textInputView.accessibilityHint = "\(requiredOrOptionalAccessibility),\(formField.instructions)\(errorAccessibility)"
    }
    
    func addSubViews() {
        // Add subviews
        addSubview(textInputLabel)
        addSubview(textInputView)
        addSubview(errorLabel)
        addSubview(instructionsLabel)
        setupConstraints()
    }
    
    func setupConstraints() {
        // Setup Constraints
        textInputLabel.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        textInputView.snp.makeConstraints { make in
            make.leading.equalTo(textInputLabel)
            make.trailing.equalTo(textInputLabel)
            make.top.equalTo(textInputLabel.snp.bottom).offset(StandardVerticalMargin/2.0)
            make.height.equalTo(textInputViewHeight)
        }
        errorLabel.snp.makeConstraints { make in
            make.leading.equalTo(textInputLabel)
            make.trailing.equalTo(textInputLabel)
            make.top.equalTo(textInputView.snp.bottom).offset(StandardVerticalMargin/2.0)
        }
        instructionsLabel.snp.makeConstraints { make in
            make.leading.equalTo(textInputLabel)
            make.trailing.equalTo(textInputLabel)
            make.top.equalTo(errorLabel.snp.bottom).offset(StandardVerticalMargin/2.0)
            make.bottom.equalTo(self).inset(StandardVerticalMargin)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Super View is not constraint base. Calculating superview height.
        let textInputLabelHeight = textInputLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let errorLabelHeight = errorLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        let instructionLabelHeight = instructionsLabel.sizeThatFits(CGSize(width: textInputView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        var height = textInputLabelHeight + errorLabelHeight + instructionLabelHeight + StandardVerticalMargin + (3.0 * StandardVerticalMargin/2.0)
        if let _ = formField { height += textInputViewHeight }
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func setValue(_ value: String) {
        if isInputTypeTextArea {
            textInputArea.text = value
        }
        else {
            textInputField.text = value
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    @objc func valueDidChange() {
        errorMessage = validate()
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_REGISTRATION_FORM_FIELD_VALUE_DID_CHANGE)))
    }
    
    func validate() -> String? {
        guard let field = formField else {
            return nil
        }
        if isRequired && currentValue == "" {
            return field.errorMessage.required == "" ? Strings.registrationFieldEmptyError(fieldName: field.label) : field.errorMessage.required
        }
        let length = currentValue.count
        if length < field.restriction.minLength {
            return field.errorMessage.minLength == "" ? Strings.registrationFieldMinLengthError(fieldName: field.label, count: "\(field.restriction.minLength)")(field.restriction.minLength) : field.errorMessage.minLength
        }
        else if length > field.restriction.maxLength && field.restriction.maxLength != 0 {
            return field.errorMessage.maxLength == "" ? Strings.registrationFieldMaxLengthError(fieldName: field.label, count: "\(field.restriction.maxLength)")(field.restriction.maxLength): field.errorMessage.maxLength
        }
        
        switch field.fieldType {
        case OEXRegistrationFieldTypeEmail:
            if hasValue && !currentValue.isValidEmailAddress() {
                return Strings.ErrorMessage.invalidEmailFormat
            }
            break
        default:
            break
        }
        return nil
    }
}

extension RegistrationFormFieldView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        valueDidChange()
    }
}
