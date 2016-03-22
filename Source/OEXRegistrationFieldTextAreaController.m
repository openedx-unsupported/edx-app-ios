//
//  OEXRegistrationFieldTextAreaController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextAreaController.h"

#import "OEXRegistrationFieldTextAreaView.h"
#import "OEXRegistrationFieldValidator.h"
#import "OEXPlaceholderTextView.h"

@interface OEXRegistrationFieldTextAreaController ()

@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) OEXRegistrationFieldTextAreaView* view;

@end

@implementation OEXRegistrationFieldTextAreaController
- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[OEXRegistrationFieldTextAreaView alloc] init];
        self.view.instructionMessage = field.instructions;
        self.view.placeholder = self.field.label;
        
        self.view.accessibilityHint = [field.instructions length] > 0 ? field.instructions : field.label;
    }
    return self;
}

- (NSString*)currentValue {
    return [[self.view currentValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)takeValue:(NSString*)value {
    return [self.view takeValue:value];
}

- (BOOL)hasValue {
    return [self currentValue] && ![[self currentValue] isEqualToString:@""];
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
    [self.view layoutIfNeeded];
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
