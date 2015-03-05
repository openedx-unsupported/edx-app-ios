//
//  OEXRegistrationFieldValidation.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 03/03/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldValidator.h"
#import "NSString+OEXFormatting.h"

@implementation OEXRegistrationFieldValidator

+(NSString *)validateField:(OEXRegistrationFormField *)field withText:(NSString *)currentValue{
    NSString *errorMessage;
    if(field.isRequired && (currentValue==nil || [currentValue isEqualToString:@""])){
        if(!field.errorMessage.required){
            NSString *localizedString = [OEXLocalizedString(@"REGISTRATION_FIELD_EMPTY_ERROR", nil) oex_uppercaseStringInCurrentLocale];
            errorMessage=[NSString stringWithFormat:localizedString,field.label];
            return errorMessage;
        }else{
            return field.errorMessage.required;
        }
    }
    
    NSInteger length=[currentValue length];
    if(length < field.restriction.minLength ){
        if(!field.errorMessage.minLength){
            NSString *localizedString = [OEXLocalizedString(@"REGISTRATION_FIELD_MIN_LENGTH_ERROR", nil) oex_uppercaseStringInCurrentLocale];
            errorMessage=[NSString stringWithFormat:localizedString,field.label,field.restriction.minLength];
            return errorMessage;
        }else{
            return  field.errorMessage.minLength;
        }
    }
    if(length > field.restriction.maxLength && field.restriction.maxLength!=0)
    {
        if(!field.errorMessage.maxLength){
            NSString *localizedString = [OEXLocalizedString(@"REGISTRATION_FIELD_MAX_LENGTH_ERROR", nil) oex_uppercaseStringInCurrentLocale];
             errorMessage=[NSString stringWithFormat:localizedString,field.label,field.restriction.maxLength];
            return errorMessage;
        }else{
            return  field.errorMessage.maxLength;
        }

    }
    return errorMessage;
}
@end
