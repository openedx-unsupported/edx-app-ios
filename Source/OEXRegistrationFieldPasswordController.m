//
//  OEXRegistrationFieldPasswordController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldPasswordController.h"
//#import "OEXRegistrationFieldPasswordView.h"
#import "OEXRegistrationFieldValidator.h"
#import "edX-Swift.h"

@interface OEXRegistrationFieldPasswordController ()
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) RegistrationFormFieldView* view;
@end

@implementation OEXRegistrationFieldPasswordController
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[RegistrationFormFieldView alloc] initWith:field];
        self.view.textInputField.secureTextEntry = YES;
//        self.view.field = field;
//        self.view.instructionMessage = field.instructions;
//        self.view.placeholder = field.label;
//        self.view.isRequired = field.isRequired;
    }
    return self;
}

- (NSString*)currentValue {
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)takeValue:(NSString*)value {
    [self.view takeValue:value];
}

- (BOOL)hasValue {
    return [self currentValue] && ![[self currentValue] isEqualToString:@""];
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
}

- (BOOL)isValidInput {
    NSString* errorMesssage = [OEXRegistrationFieldValidator validateField:self.field withText:[self currentValue]];
    if(errorMesssage) {
        [self handleError:errorMesssage];
        return NO;
    }
    return YES;
}

-  (UIView*)accessibleInputField {
    return self.view.textInputField;
}

@end
