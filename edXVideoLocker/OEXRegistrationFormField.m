//
//  OEXRegistrationFormField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormField.h"




@interface OEXRegistrationFormField ()
@property(nonatomic,strong)OEXRegistrationOption *defaultOption;
@property(nonatomic,strong)NSMutableArray *options;
@end

@implementation OEXRegistrationFormField

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _name=dictionary[@"name"];
        _isRequired=[dictionary[@"required"] boolValue];
        _placeholder=dictionary[@"placeholder"];
        _defaultValue=dictionary[@"defaultValue"];
        _instructions=dictionary[@"instructions"];
        _label=dictionary[@"label"];
        _type=dictionary[@"type"];
        _fieldType=[self registrationFieldType:dictionary[@"type"]];
        _errorMessage=[[OEXRegistrationErrorMessage alloc] initWithDictionary:dictionary[@"errorMessages"]];
        if(dictionary[@"agreement"]){
            _agreement=[[OEXRegistrationAgreement alloc] initWithDictionary:dictionary[@"agreement"]];
            _fieldType=OEXRegistrationFieldTypeAgreement;
        }
        _restriction=[[OEXRegistrationRestriction alloc] initWithDictionary:dictionary[@"restrictions"]];
        
        NSArray *array=dictionary[@"options"];
        self.options=[[NSMutableArray alloc] init];
        for (NSDictionary *dict in  array) {
            
            OEXRegistrationOption *option=[[OEXRegistrationOption alloc] initWithDictionary:dict];
            if(option.isDefault){
                _defaultOption=option;
            }
            if(option){
                [self.options addObject:option];
            }
        }
    }
    return self;
}


-(OEXRegistrationFieldType)registrationFieldType:(NSString *)strType{
    if([strType isEqualToString:@"email"]){
        return OEXRegistrationFieldTypeEmail;
    }else if([strType isEqualToString:@"password"]){
        return OEXRegistrationFieldTypePassword;
    }else if([strType isEqualToString:@"text"]){
        return OEXRegistrationFieldTypeText;
    }else if([strType isEqualToString:@"textarea"]){
        return OEXRegistrationFieldTypeTextArea;
    }else if([strType isEqualToString:@"select"]){
        return OEXRegistrationFieldTypeSelect;
    }else if([strType isEqualToString:@"checkbox"]){
        return OEXRegistrationFieldTypeCheckbox;
    }else{
        return OEXRegistrationFieldTypeUnknown;
    }
}


// NSArray : OEXRegistrationOption
-(NSArray *)fieldOptions{
    return [NSArray arrayWithArray:self.options];
}

@end
