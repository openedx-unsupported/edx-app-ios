//
//  RegistrationFieldController.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 23/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//


class RegistrationFieldController: NSObject, OEXRegistrationFieldController {
    

    
    var _field: OEXRegistrationFormField
    var _view: RegistrationFormFieldView
    
    
    var view: UIView{
        return _view
    }
    
    var field: OEXRegistrationFormField{
        return _field
    }
    var hasValue: Bool{
        return stringValue != ""
    }
    
    var accessibleInputField: UIView?{
        return _view.textInputField
    }
    var stringValue: String{
        if let value = currentValue() as? String{
            return value
        }
        return ""
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
        self._field = formField
        self._view = RegistrationFormFieldView(with: formField)
        switch formField.fieldType {
        case OEXRegistrationFieldTypeEmail:
            _view.textInputField.keyboardType = .emailAddress
            _view.textInputField.accessibilityIdentifier = "field-\(_field.name)"
            break
        case OEXRegistrationFieldTypePassword:
            _view.textInputField.isSecureTextEntry = true
            break
        default:
            break
        }
        
    }
    
    /// id should be a JSON safe type.
    func currentValue() -> Any {
        if let currentValue = _view.currentValue{
            return currentValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
        }
        return ""
    }
    
    func takeValue(_ value: Any) {
        if let value = value as? String {
            _view.takeValue(value)
        }
    }
    
    func handleError(_ errorMessage: String?) {
        if let errorMessage = errorMessage{
            _view.errorMessage = errorMessage
        }
        else{
            _view.errorMessage = ""
        }
    }
    
    
    private func validate() -> String?{
        if _field.isRequired && stringValue == "" {
            return _field.errorMessage.required == "" ? Strings.registrationFieldEmptyError(fieldName: _field.label) : _field.errorMessage.required
        }
        let length = stringValue.characters.count
        if length < _field.restriction.minLength {
            return _field.errorMessage.minLength == "" ? Strings.registrationFieldMinLengthError(fieldName: _field.label, count: "\(_field.restriction.minLength)")(_field.restriction.minLength) : _field.errorMessage.minLength
        }
        if length > _field.restriction.maxLength && _field.restriction.maxLength != 0{
            return _field.errorMessage.maxLength == "" ? Strings.registrationFieldMaxLengthError(fieldName: _field.label, count: "\(_field.restriction.maxLength)")(_field.restriction.maxLength): _field.errorMessage.maxLength
        }
        return nil
    }
    
}
