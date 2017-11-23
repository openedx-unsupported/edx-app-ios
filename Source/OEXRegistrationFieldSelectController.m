//
//  OEXRegistrationFieldSelectController.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

@import edXCore;

#import "OEXRegistrationFieldSelectController.h"

#import "edX-Swift.h"

@interface OEXRegistrationFieldSelectController ()
@property(nonatomic, strong) OEXRegistrationFormField* field;
@property(nonatomic, strong) RegistrationFieldSelectView* view;
@end

@implementation OEXRegistrationFieldSelectController

- (instancetype)initWithRegistrationFormField:(OEXRegistrationFormField*)field {
    self = [super init];
    if(self) {
        self.field = field;
        self.view = [[RegistrationFieldSelectView alloc] init];
        self.view.instructionMessage = field.instructions;
        self.view.placeholder = field.label;
        self.view.options = self.field.fieldOptions;
        self.view.accessibilityIdentifier = [NSString stringWithFormat:@"field-%@", field.name];
        self.view.picker.accessibilityIdentifier = [NSString stringWithFormat:@"picker-field-%@", field.name];
        self.view.fieldType = [field registrationFieldType:field.type];
    }
    return self;
}

- (NSString*)currentValue {
    return [self.view.selected.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)takeValue:(NSString*)value {
    if(value && [self.field.fieldOptions containsObject:value]) {
        [self.view takeValue:value];
    }
}

- (BOOL)hasValue {
    return [self currentValue] && ![[self currentValue] isEqualToString:@""];
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
}

- (BOOL)isValidInput {
    if(self.field.isRequired && ![self hasValue]) {
        if(!self.field.errorMessage.required) {
            NSString* error = [Strings registrationFieldEmptySelectErrorWithFieldName:self.field.label];
            [self handleError:error];
        }
        else {
            [self handleError:self.field.errorMessage.required];
        }
        return NO;
    }
    return YES;
}
- (UIView*)accessibleInputField {
    return self.view;
}

@end
