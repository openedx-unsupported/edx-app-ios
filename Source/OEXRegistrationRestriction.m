//
//  OEXRegistrationRestriction.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationRestriction.h"

@implementation OEXRegistrationRestriction

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _maxLength = [dictionary[@"max_length"] integerValue];
        _minLength = [dictionary[@"min_length"] integerValue];
    }
    return self;
}

@end
