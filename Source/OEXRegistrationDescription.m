//
//  OEXRegistrationDescription.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationDescription.h"
#import "OEXRegistrationFormField.h"
#import "NSArray+OEXFunctional.h"

@interface OEXRegistrationDescription ()

@property (nonatomic, copy) NSArray* registrationFormFields;
@property (nonatomic, copy) NSString* method;
@property (nonatomic, copy) NSString* submitUrl;

@end

@implementation OEXRegistrationDescription

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        self.submitUrl = dictionary[@"submit_url"];
        self.method = dictionary[@"method"];
        NSArray* fieldInfos = dictionary[@"fields"];
        self.registrationFormFields = [fieldInfos oex_map:^id (NSDictionary* fieldDictionary) {
            return [[OEXRegistrationFormField alloc] initWithDictionary:fieldDictionary];
        }];
    }
    return self;
}

- (id)initWithFields:(NSArray*)fields method:(NSString*)method submitURL:(NSString*)submitURL {
    if(self != nil) {
        self.registrationFormFields = fields;
        self.method = method;
        self.submitUrl = submitURL;
    }
    return self;
}

@end
