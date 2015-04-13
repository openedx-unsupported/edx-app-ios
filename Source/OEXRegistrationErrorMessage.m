//
//  OEXRegistrationMessage.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationErrorMessage.h"

@implementation OEXRegistrationErrorMessage

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _maxLength = dictionary[@"min_length"];
        _minLength = dictionary[@"min_length"];
        _required = dictionary[@"required"];
    }
    return self;
}

@end
