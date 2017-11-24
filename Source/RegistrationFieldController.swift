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
        
        if let errorMessage = OEXRegistrationFieldValidator.validate(_field, withText: self.stringValue) {
            self.handleError(errorMessage)
            return false
        }
        
        switch field.fieldType {
        case OEXRegistrationFieldTypeEmail:
            if hasValue && !stringValue.isValidEmailAddress(){
                self.handleError("Please make sure your e-mail address is formatted correctly and try again.")
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
            self._view.textInputField.keyboardType = .emailAddress
            self._view.textInputField.accessibilityIdentifier = "field-\(_field.name)"
            break
        case OEXRegistrationFieldTypePassword:
            self._view.textInputField.isSecureTextEntry = true
            break
        case OEXRegistrationFieldTypeTextArea:
            self._view.accessibilityHint = _field.instructions != "" ? _field.instructions : _field.label
            break
        default:
            break
        }
        
    }
    
    /// id should be a JSON safe type.
    func currentValue() -> Any {
        return _view.currentValue.trimmingCharacters(in: NSCharacterSet.whitespaces)
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
    
    
}
