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
    
    
    var view: UIView{
        return fieldView
    }
    
    var hasValue: Bool{
        return stringValue != ""
    }
    
    var accessibleInputField: UIView?{
        return fieldView.textInputField
    }
    private var stringValue: String{
        return currentValue() as? String ?? ""
    }
    var isValidInput: Bool{
        if let errorMessage = validate() {
            self.handleError(errorMessage)
            return false
        }
        
        switch field.fieldType {
        case OEXRegistrationFieldTypeEmail:
            if hasValue && !stringValue.isValidEmailAddress(){
                handleError(Strings.ErrorMessage.invalidEmailFormat)
                return false;
            }
            break
        default:
            break
        }
        return true
    }
    
    init(with formField: OEXRegistrationFormField) {
        field = formField
        fieldView = RegistrationFormFieldView(with: formField)
        switch formField.fieldType {
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
        return fieldView.currentValue?.trimmingCharacters(in: NSCharacterSet.whitespaces) ?? ""
    }
    
    func takeValue(_ value: Any) {
        if let value = value as? String {
            fieldView.takeValue(value)
        }
    }
    
    func handleError(_ errorMessage: String?) {
        fieldView.errorMessage = errorMessage
    }
    
    
    private func validate() -> String?{
        if field.isRequired && stringValue == "" {
            return field.errorMessage.required == "" ? Strings.registrationFieldEmptyError(fieldName: field.label) : field.errorMessage.required
        }
        let length = stringValue.characters.count
        if length < field.restriction.minLength {
            return field.errorMessage.minLength == "" ? Strings.registrationFieldMinLengthError(fieldName: field.label, count: "\(field.restriction.minLength)")(field.restriction.minLength) : field.errorMessage.minLength
        }
        if length > field.restriction.maxLength && field.restriction.maxLength != 0{
            return field.errorMessage.maxLength == "" ? Strings.registrationFieldMaxLengthError(fieldName: field.label, count: "\(field.restriction.maxLength)")(field.restriction.maxLength): field.errorMessage.maxLength
        }
        return nil
    }
    
}
