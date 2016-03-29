//
//  OEXRegistrationFieldTextController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextController.h"
#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationFieldValidator.h"
@interface OEXRegistrationFieldTextController ()
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) OEXRegistrationFormTextField* view;
@end

@implementation OEXRegistrationFieldTextController

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[OEXRegistrationFormTextField alloc] init];
        self.view.instructionMessage = field.instructions;
        self.view.placeholder = field.label;
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
    return self.view.textInputView;
}

@end
