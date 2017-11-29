//
//  RegistrationAgreementController.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 28/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

class RegistrationAgreementController: NSObject, OEXRegistrationFieldController {
    
    var _view: RegistrationAgreementView
    var _field: OEXRegistrationFormField
    
    
    var view: UIView{
        return _view
    }
    
    var field: OEXRegistrationFormField{
        return _field
    }
    var hasValue: Bool{
        return true
    }
    
    var accessibleInputField: UIView?{
        return nil
    }
    
    var isValidInput: Bool{
        if self.field.isRequired && !(self.currentValue() as! Bool) {
            self.handleError(self.field.errorMessage.required)
            return false
        }
        

        return true
    }
     init(with formField: OEXRegistrationFormField) {
        _field = formField
        _view = RegistrationAgreementView(with: formField)
    }
    
    /// id should be a JSON safe type.
    func currentValue() -> Any
    {
        return _view.currentValue
    }
    
    func takeValue(_ value: Any) {
        
    }
    
    func handleError(_ errorMessage: String?) {
        if let errorMessage = errorMessage{
            _view.errorMessage = errorMessage
        }
        else{
            _view.errorMessage = nil
        }
    }
}
