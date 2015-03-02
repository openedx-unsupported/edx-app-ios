//
//  OEXRegistrationDescription.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFormField.h"
@interface OEXRegistrationDescription ()
@property(nonatomic,strong)NSMutableArray *fields;
@end

@implementation OEXRegistrationDescription

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        self.submitUrl=dictionary[@"submit_url"];
        self.method=dictionary[@"method"];
        self.fields=[[NSMutableArray alloc] init];
        NSArray *arrDict=dictionary[@"fields"];
        for (NSDictionary *dict in arrDict) {
            OEXRegistrationFormField *field=[[OEXRegistrationFormField alloc] initWithDictionary:dict];
            if(field){
                [self.fields addObject:field];
            }
        }
    }
    return self;
}

-(NSArray *)registrationFormFields{
    
    return [NSArray arrayWithArray:self.fields];
    
}


@end
