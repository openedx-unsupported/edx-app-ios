//
//  OEXRegistrationFormField.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXRegistrationOption.h"
#import "OEXRegistrationRestriction.h"
#import "OEXRegistrationAgreement.h"
#import "OEXRegistrationRestriction.h"
#import "OEXRegistrationErrorMessage.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum
{
    OEXRegistrationFieldTypeEmail,
    OEXRegistrationFieldTypePassword,
    OEXRegistrationFieldTypeText,
    OEXRegistrationFieldTypeTextArea,
    OEXRegistrationFieldTypeCheckbox,
    OEXRegistrationFieldTypeSelect,
    OEXRegistrationFieldTypeAgreement,
    OEXRegistrationFieldTypeUnknown
}OEXRegistrationFieldType;

@interface OEXRegistrationFormField : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (readonly, nonatomic, assign) BOOL isRequired;

@property (readonly, nonatomic, copy) NSString* name;
@property (readonly, nonatomic, copy) NSString* placeholder;
@property (readonly, nonatomic, copy) NSString* defaultValue;
@property (readonly, nonatomic, copy) NSString* instructions;
@property (readonly, nonatomic, copy) NSString* label;
@property (readonly, nonatomic, copy) NSString* type;

@property (readonly, nonatomic, assign) OEXRegistrationFieldType fieldType;
@property (readonly, nonatomic, strong) OEXRegistrationOption* defaultOption;
@property (nonatomic, strong) OEXRegistrationAgreement* agreement;
@property (readonly, nonatomic, strong) OEXRegistrationRestriction* restriction;
@property (readonly, nonatomic, strong) OEXRegistrationErrorMessage* errorMessage;

/// Contents are OEXRegistrationOption*
@property (readonly, nonatomic, copy) NSArray* fieldOptions;

- (OEXRegistrationFieldType)registrationFieldType:(NSString*)fieldType;

@end

@interface OEXMutableRegistrationFormField : OEXRegistrationFormField

@property (nonatomic, assign) BOOL isRequired;

@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* placeholder;
@property (nonatomic, copy) NSString* defaultValue;
@property (nonatomic, copy) NSString* instructions;
@property (nonatomic, copy) NSString* label;
@property (nonatomic, copy) NSString* type;

@property (nonatomic) OEXRegistrationFieldType fieldType;
@property (nonatomic, strong) OEXRegistrationOption* defaultOption;
@property (nonatomic, strong) OEXRegistrationAgreement* agreement;
@property (nonatomic, strong) OEXRegistrationRestriction* restriction;
@property (nonatomic, strong) OEXRegistrationErrorMessage* errorMessage;

@property (nonatomic, copy) NSArray* fieldOptions;

@end

NS_ASSUME_NONNULL_END
