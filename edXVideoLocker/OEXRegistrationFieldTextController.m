//
//  OEXRegistrationFieldTextController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextController.h"
#import "OEXRegistrationFormTextField.h"
@interface OEXRegistrationFieldTextController ()
    @property(nonatomic,strong)OEXRegistrationFormField *field;
    @property(nonatomic,strong)OEXRegistrationFormTextField *view;
@end

@implementation OEXRegistrationFieldTextController

-(instancetype)initWithRegistrationFormField:(OEXRegistrationFormField *)field{
    self=[super init];
    if(self){
        self.field=field;
        self.view=[[OEXRegistrationFormTextField alloc] init];
        self.view.instructionMessage=field.instructions;
        self.view.placeholder=field.label;
    }
    return self;
}

-(NSString *)currentValue{
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

-(BOOL)hasValue{
    return [self currentValue]&& ![[self currentValue] isEqualToString:@""];
}

-(void)handleError:(NSString *)errorMsg{
    [self.view setErrorMessage:errorMsg];
}

-(BOOL)isValidInput{
    
    if(self.field.isRequired && ![self hasValue]){
        if(!self.field.errorMessage.required){
            NSString *localizedString = NSLocalizedString(@"REGISTRATION_FIELD_EMPTY_ERROR", nil);
            NSString *error=[NSString stringWithFormat:localizedString,self.field.label];
            [self handleError:error];
        }else{
            [self handleError:self.field.errorMessage.required];
        }
        return NO;
    }
    
    NSInteger length=[[self currentValue] length];
    if(length < self.field.restriction.minLength ){
        if(!self.field.errorMessage.minLength){
            NSString *localizedString = NSLocalizedString(@"REGISTRATION_FIELD_MIN_LENGTH_ERROR", nil);
            NSString *error=[NSString stringWithFormat:localizedString,self.field.label,self.field.restriction.minLength];
            [self handleError:error];
        }else{
            [self handleError:self.field.errorMessage.minLength];
        }
        return NO;
    }
    if(length > self.field.restriction.maxLength && self.field.restriction.maxLength!=0)
    {
        if(!self.field.errorMessage.maxLength){
            NSString *localizedString = NSLocalizedString(@"REGISTRATION_FIELD_MAX_LENGTH_ERROR", nil);
            NSString *error=[NSString stringWithFormat:localizedString,self.field.label,self.field.restriction.maxLength];
            [self handleError:error];
        }else{
            [self handleError:self.field.errorMessage.maxLength];
        }
        return NO;
    }
    return YES;
}
@end
