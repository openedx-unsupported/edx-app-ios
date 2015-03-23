//
//  OEXRegistrationOption.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationOption.h"

@implementation OEXRegistrationOption

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _name = dictionary[@"name"];
        _value = dictionary[@"value"];
        _isDefault = [dictionary[@"default"] boolValue];
    }
    return self;
}

@end
