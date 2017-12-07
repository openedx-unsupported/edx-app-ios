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
        self.view = [[RegistrationFieldSelectView alloc] initWith:field];
        self.view.options = self.field.fieldOptions;
        self.view.accessibilityIdentifier = [NSString stringWithFormat:@"field-%@", field.name];
        self.view.picker.accessibilityIdentifier = [NSString stringWithFormat:@"picker-field-%@", field.name];
    }
    return self;
}

- (NSString*)currentValue {
    return [self.view.selected.value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)setValue:(NSString*)value {
    if(value && [self.field.fieldOptions containsObject:value]) {
        [self.view setValue:value];
    }
}

- (BOOL)hasValue {
    return [self currentValue] && ![[self currentValue] isEqualToString:@""];
}

- (void)handleError:(NSString*)errorMsg {
    [self.view setErrorMessage:errorMsg];
}

- (BOOL)isValidInput {
    return self.view.isValidInput;
}
- (UIView*)accessibleInputField {
    return self.view;
}

@end
