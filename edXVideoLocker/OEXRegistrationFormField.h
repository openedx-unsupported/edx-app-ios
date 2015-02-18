//
//  OEXRegistrationFormField.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXRegistrationOption.h"
#import "OEXRegistrationRestriction.h"
#import "OEXRegistrationAgreement.h"
#import "OEXRegistrationRestriction.h"
#import "OEXRegistrationErrorMessage.h"
typedef enum {
    
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

@property(readonly,nonatomic,copy)NSNumber *isRequired;
@property(readonly,nonatomic,copy)NSString *name;
@property(readonly,nonatomic,copy)NSString *placeholder;
@property(readonly,nonatomic,copy)NSString *defaultValue;
@property(readonly,nonatomic,copy)NSString *instructions;
@property(readonly,nonatomic,copy)NSString *label;
@property(readonly,nonatomic,copy)NSString *type;
@property(readonly,nonatomic,assign)OEXRegistrationFieldType    fieldType;
@property(readonly,nonatomic,strong)OEXRegistrationOption       *defaultOption;
@property(readonly,nonatomic,strong)OEXRegistrationAgreement    *agreement;
@property(readonly,nonatomic,strong)OEXRegistrationRestriction  *restriction;
@property(readonly,nonatomic,strong)OEXRegistrationErrorMessage *errorMessage;

-(instancetype)initWithDictionary:(NSDictionary *)dictionary;

// NSArray : OEXRegistrationOption

-(NSArray *)fieldOptions;

@end
