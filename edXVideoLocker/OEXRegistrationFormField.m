//
//  OEXRegistrationFormField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormField.h"

#import "NSArray+OEXFunctional.h"

@interface OEXRegistrationFormField ()

@property (nonatomic, assign) BOOL isRequired;

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* placeholder;
@property (nonatomic, copy) NSString* defaultValue;
@property (nonatomic, copy) NSString* instructions;
@property (nonatomic, copy) NSString* label;
@property (nonatomic, copy) NSString* type;

@property (nonatomic, assign) OEXRegistrationFieldType fieldType;
@property (nonatomic, strong) OEXRegistrationOption* defaultOption;
@property (nonatomic, strong) OEXRegistrationAgreement* agreement;
@property (nonatomic, strong) OEXRegistrationRestriction* restriction;
@property (nonatomic, strong) OEXRegistrationErrorMessage* errorMessage;

@property (nonatomic, copy) NSArray* fieldOptions;

@end

@implementation OEXRegistrationFormField

-(instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        self.name = dictionary[@"name"];
        self.isRequired = [dictionary[@"required"] boolValue];
        self.placeholder = dictionary[@"placeholder"];
        self.defaultValue = dictionary[@"defaultValue"];
        self.instructions = dictionary[@"instructions"];
        self.label = dictionary[@"label"];
        self.type = dictionary[@"type"];
        self.fieldType = [self registrationFieldType:dictionary[@"type"]];
        self.errorMessage = [[OEXRegistrationErrorMessage alloc] initWithDictionary:dictionary[@"errorMessages"]];
        if(dictionary[@"agreement"]) {
            self.agreement = [[OEXRegistrationAgreement alloc] initWithDictionary:dictionary[@"agreement"]];
            self.fieldType = OEXRegistrationFieldTypeAgreement;
        }
        self.restriction = [[OEXRegistrationRestriction alloc] initWithDictionary:dictionary[@"restrictions"]];

        NSArray* options = dictionary[@"options"];
        self.fieldOptions = [options oex_map:^id (NSDictionary* optionInfo) {
                                 OEXRegistrationOption* option = [[OEXRegistrationOption alloc] initWithDictionary:optionInfo];
                                 if(option != nil) {
                                     self.defaultOption = option;
                                 }
                                 return option;
                             }];
    }
    return self;
}

-(OEXRegistrationFieldType)registrationFieldType:(NSString*)strType {
    if([strType isEqualToString:@"email"]) {
        return OEXRegistrationFieldTypeEmail;
    }
    else if([strType isEqualToString:@"password"]) {
        return OEXRegistrationFieldTypePassword;
    }
    else if([strType isEqualToString:@"text"]) {
        return OEXRegistrationFieldTypeText;
    }
    else if([strType isEqualToString:@"textarea"]) {
        return OEXRegistrationFieldTypeTextArea;
    }
    else if([strType isEqualToString:@"select"]) {
        return OEXRegistrationFieldTypeSelect;
    }
    else if([strType isEqualToString:@"checkbox"]) {
        return OEXRegistrationFieldTypeCheckbox;
    }
    else {
        return OEXRegistrationFieldTypeUnknown;
    }
}

@end

@implementation OEXMutableRegistrationFormField

@end