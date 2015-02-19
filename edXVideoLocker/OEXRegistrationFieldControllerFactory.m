//
//  OEXRegistrationFieldControllerFactory.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldControllerFactory.h"
#import "OEXRegistrationFieldEmailController.h"
#import "OEXRegistrationFieldSelectView.h"
#import "OEXRegistrationFieldTextAreaController.h"
#import "OEXRegistrationFieldTextController.h"
#import "OEXRegistrationFieldPasswordController.h"
#import "OEXRegistrationFieldSelectController.h"
#import "OEXRegistrationFieldCheckBoxController.h"
#import "OEXRegistrationAgreementController.h"
@implementation OEXRegistrationFieldControllerFactory

+(id <OEXRegistrationFieldProtocol> )registrationFieldViewController:(OEXRegistrationFormField *)registrationField{
    
    switch (registrationField.fieldType) {
            
        case OEXRegistrationFieldTypePassword:
            return [OEXRegistrationFieldControllerFactory  passwordFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeText:
            return [OEXRegistrationFieldControllerFactory  textFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeTextArea:
            return [OEXRegistrationFieldControllerFactory  textAreaFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeSelect:
            return [OEXRegistrationFieldControllerFactory  selectFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeEmail:
            return [OEXRegistrationFieldControllerFactory emailFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeCheckbox:
            return [OEXRegistrationFieldControllerFactory checkboxFieldControllerWith:registrationField];
        case OEXRegistrationFieldTypeAgreement:
            return [OEXRegistrationFieldControllerFactory registrationAgreementControllerWith:registrationField];
        default:
            break;
    }
    
    NSAssert(NO, @"Registration field type is unknown");
    
    return nil;
    
    
}

+(id <OEXRegistrationFieldProtocol>)emailFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldEmailController alloc] initWithRegistrationFormField:formField];
    
}

+(id <OEXRegistrationFieldProtocol>)selectFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldSelectController alloc] initWithRegistrationFormField:formField];
    
}

+(id <OEXRegistrationFieldProtocol>)textFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldTextController alloc] initWithRegistrationFormField:formField];
    
}
+(id <OEXRegistrationFieldProtocol>)passwordFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldPasswordController alloc] initWithRegistrationFormField:formField];
    
}
+(id <OEXRegistrationFieldProtocol>)checkboxFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldCheckBoxController alloc] initWithRegistrationFormField:formField];
    
}

+(id <OEXRegistrationFieldProtocol>)textAreaFieldControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationFieldTextAreaController alloc] initWithRegistrationFormField:formField];
    
}
+(id <OEXRegistrationFieldProtocol>)registrationAgreementControllerWith:(OEXRegistrationFormField *)formField{
    
    return [[OEXRegistrationAgreementController alloc] initWithRegistrationFormField:formField];
    
}


@end
