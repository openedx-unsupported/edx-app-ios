//
//  OEXRegistrationFormField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormField.h"

#import "NSArray+OEXFunctional.h"
#import "OEXConfig.h"

@interface OEXRegistrationFormField ()

@property (nonatomic, assign) BOOL isRequired;

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* placeholder;
@property (nonatomic, copy) NSString* defaultValue;
@property (nonatomic, copy) NSString* instructions;
@property (nonatomic, copy) NSString* label;
@property (nonatomic, copy) NSString* type;

@property (nonatomic) OEXRegistrationFieldType fieldType;
@property (nonatomic, strong) OEXRegistrationOption* defaultOption;
@property (nonatomic, strong) OEXRegistrationRestriction* restriction;
@property (nonatomic, strong) OEXRegistrationErrorMessage* errorMessage;

@property (nonatomic, copy) NSArray* fieldOptions;

@end

@implementation OEXRegistrationFormField

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        self.name = dictionary[@"name"];
        self.isRequired = [dictionary[@"required"] boolValue];
        self.placeholder = dictionary[@"placeholder"];
        self.defaultValue = dictionary[@"defaultValue"];
        self.instructions = dictionary[@"instructions"];
        self.label = dictionary[@"label"];
        if (self.instructions.length > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAttributedString *attributedLabel = [[NSAttributedString alloc] initWithData:[self.instructions dataUsingEncoding:NSUTF8StringEncoding]
                                                                                       options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                                 NSCharacterEncodingDocumentAttribute:@(NSUTF8StringEncoding)}
                                                                            documentAttributes:nil
                                                                                         error:nil];
                self.instructions = attributedLabel.string;
            });
        }
        self.type = dictionary[@"type"];
        self.fieldType = [self registrationFieldType:dictionary[@"type"]];
        self.errorMessage = [[OEXRegistrationErrorMessage alloc] initWithDictionary:dictionary[@"errorMessages"]];
        if(dictionary[@"agreement"]) {
            self.agreement = [[OEXRegistrationAgreement alloc] initWithDictionary:dictionary[@"agreement"]];
            self.fieldType = OEXRegistrationFieldTypeAgreement;
        }
        self.restriction = [[OEXRegistrationRestriction alloc] initWithDictionary:dictionary[@"restrictions"]];
        if([dictionary[@"name"] isEqualToString:@"honor_code"]) {
            self.fieldType = OEXRegistrationFieldTypeAgreement;
        }
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

- (OEXRegistrationFieldType)registrationFieldType:(NSString*)fieldType {
    if([fieldType isEqualToString:@"email"]) {
        return OEXRegistrationFieldTypeEmail;
    }
    else if([fieldType isEqualToString:@"password"]) {
        return OEXRegistrationFieldTypePassword;
    }
    else if([fieldType isEqualToString:@"text"]) {
        return OEXRegistrationFieldTypeText;
    }
    else if([fieldType isEqualToString:@"textarea"]) {
        return OEXRegistrationFieldTypeTextArea;
    }
    else if([fieldType isEqualToString:@"select"]) {
        return OEXRegistrationFieldTypeSelect;
    }
    else if([fieldType isEqualToString:@"checkbox"]) {
        return OEXRegistrationFieldTypeAgreement;
    }
    else {
        return OEXRegistrationFieldTypeUnknown;
    }
}

@end

@implementation OEXMutableRegistrationFormField

@dynamic agreement;
@dynamic defaultOption;
@dynamic defaultValue;
@dynamic errorMessage;
@dynamic fieldOptions;
@dynamic fieldType;
@dynamic isRequired;
@dynamic name;
@dynamic placeholder;
@dynamic instructions;
@dynamic label;
@dynamic type;
@dynamic restriction;

@end
