//
//  OEXRegistrationAgreement.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 13/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreement.h"

@implementation OEXRegistrationAgreement

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _url = dictionary[@"url"];
        _text = dictionary[@"text"];
    }
    return self;
}
@end
