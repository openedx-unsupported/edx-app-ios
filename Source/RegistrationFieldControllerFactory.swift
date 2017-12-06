//
//  RegistrationFieldControllerFactory.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 24/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

@objc class RegistrationFieldControllerFactory : NSObject {
    
    open class func registrationController(of field: OEXRegistrationFormField) -> OEXRegistrationFieldController? {
        switch field.fieldType {
        case OEXRegistrationFieldTypeText,
             OEXRegistrationFieldTypeEmail,
             OEXRegistrationFieldTypePassword,
             OEXRegistrationFieldTypeTextArea:
            return RegistrationFieldController(with: field)
        case OEXRegistrationFieldTypeSelect:
            return OEXRegistrationFieldSelectController(registrationFormField: field)
        case OEXRegistrationFieldTypeCheckbox:
            return OEXRegistrationFieldCheckBoxController(registrationFormField: field)
        default:
            break
        }
        return nil
    }
    
}
