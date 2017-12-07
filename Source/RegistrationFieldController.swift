//
//  RegistrationFieldController.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 23/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//


class RegistrationFieldController: NSObject, OEXRegistrationFieldController {
    
    var field: OEXRegistrationFormField
    var fieldView: RegistrationFormFieldView
    
    var view: UIView {
        return fieldView
    }
    
    var hasValue: Bool {
        return fieldView.hasValue
    }
    var accessibleInputField: UIView? {
        return fieldView.textInputView
    }
    
    var isValidInput: Bool {
        return fieldView.isValidInput
    }
    
    init(with formField: OEXRegistrationFormField) {
        field = formField
        fieldView = RegistrationFormFieldView(with: formField)
        super.init()
        setupView()
    }
    private func setupView() {
        switch field.fieldType {
        case OEXRegistrationFieldTypeEmail:
            fieldView.textInputField.keyboardType = .emailAddress
            fieldView.textInputField.accessibilityIdentifier = "field-\(field.name)"
            break
        case OEXRegistrationFieldTypePassword:
            fieldView.textInputField.isSecureTextEntry = true
            break
        default:
            break
        }
    }
    
    /// id should be a JSON safe type.
    func currentValue() -> Any {
        return fieldView.currentValue
    }
    
    func setValue(_ value: Any) {
        if let value = value as? String {
            fieldView.setValue(value)
        }
    }
    
    func handleError(_ errorMessage: String?) {
        fieldView.errorMessage = errorMessage
    }
}
