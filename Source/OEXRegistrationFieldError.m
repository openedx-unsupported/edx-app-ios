//
//  OEXRegistrationFieldError.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldError.h"

@interface OEXRegistrationFieldError ()

@property (copy, nonatomic) NSString* userMessage;

@end

@implementation OEXRegistrationFieldError

- (id)initWithDictionary:(NSDictionary*)info {
    self = [super init];
    if(self != nil) {
        self.userMessage = info[@"user_message"];
    }
    return self;
}

@end
