//
//  OEXRegistrationAgreementController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreementController.h"
#import "OEXRegistrationAgreementView.h"
#import "OEXRegistrationFormField.h"

@interface OEXRegistrationAgreementController ()
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) OEXRegistrationAgreementView* view;
@end
@implementation OEXRegistrationAgreementController

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[OEXRegistrationAgreementView alloc] init];
        self.view.instructionMessage = field.instructions;
        self.view.agreement = field.agreement.text;
        self.view.agreementUrl = field.agreement.url;
    }
    return self;
}

- (id)currentValue {
    return @([self.view currentValue]);
}

- (void)takeValue:(id)value {
    // Do nothing. This has no value
}

- (BOOL)hasValue {
    return ([self currentValue] != nil);
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
    [self.view layoutIfNeeded];
}

- (BOOL)isValidInput {
    if(self.field.isRequired && ![[self currentValue] boolValue]) {
        [self handleError:self.field.errorMessage.required];
        return NO;
    }
    return YES;
}

- (UIView*)accessibleInputField {
    return nil;
}

@end
