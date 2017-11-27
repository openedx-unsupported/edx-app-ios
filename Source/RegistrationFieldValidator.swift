//
//  RegistrationFieldValidator.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 24/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

@objc class RegistrationFieldValidator: NSObject{
    
    open class func validate(text:String, of field: OEXRegistrationFormField ) -> String?{
    
        
        if field.isRequired && text == "" {
            if field.errorMessage.required == ""{
                return Strings.registrationFieldEmptyError(fieldName: field.label)
            }
            else{
                return field.errorMessage.required
            }
        }
        
        let length = text.characters.count
        if length < field.restriction.minLength {
            if field.errorMessage.minLength == "" {
                return Strings.registrationFieldMinLengthError(fieldName: field.label, count: "\(field.restriction.minLength)")(field.restriction.minLength)
            }
            else{
                return field.errorMessage.minLength
            }
        }
        
        if length > field.restriction.maxLength && field.restriction.maxLength != 0{
            if field.errorMessage.maxLength == ""{
                return Strings.registrationFieldMaxLengthError(fieldName: field.label, count: "\(field.restriction.maxLength)")(field.restriction.maxLength)
            }
            else{
                return field.errorMessage.maxLength
            }
        }
        
        return nil
    }
    
}

//+ (NSString*)validateField:(OEXRegistrationFormField*)field withText:(NSString*)currentValue {
//    NSString* errorMessage;
//    if(field.isRequired && (currentValue == nil || [currentValue isEqualToString:@""])) {
//        if(!field.errorMessage.required) {
//            return [Strings registrationFieldEmptyErrorWithFieldName:field.label];
//        }
//        else {
//            return field.errorMessage.required;
//        }
//    }
//    
//    NSInteger length = [currentValue length];
//    if(length < field.restriction.minLength) {
//        if(!field.errorMessage.minLength) {
//            return [Strings registrationFieldMinLengthErrorWithFieldName:field.label count:@(field.restriction.minLength).description](field.restriction.minLength);
//        }
//        else {
//            return field.errorMessage.minLength;
//        }
//    }
//    if(length > field.restriction.maxLength && field.restriction.maxLength != 0) {
//        if(!field.errorMessage.maxLength) {
//            NSString* errorMessage = [Strings registrationFieldMaxLengthErrorWithFieldName:field.label count:@(field.restriction.maxLength).description](field.restriction.maxLength);
//            return errorMessage;
//        }
//        else {
//            return field.errorMessage.maxLength;
//        }
//    }
//    return errorMessage;
//}
