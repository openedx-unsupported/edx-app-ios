//
//  OEXFacebookConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFacebookConfig.h"

static NSString* const OEXFacebookAppID = @"FACEBOOK_APP_ID";
static NSString* const OEXFacebookConfigKey = @"FACEBOOK";
static NSString* const OEXFacebookEnabledKey = @"ENABLED";

@implementation OEXFacebookConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[OEXFacebookEnabledKey] boolValue];
        _appId = dictionary[OEXFacebookAppID];
    }
    return self;
}
@end


@implementation OEXConfig (Facebook)

- (OEXFacebookConfig*)facebookConfig {
    NSDictionary* dictionary = [self objectForKey:OEXFacebookConfigKey];
    OEXFacebookConfig* facebookConfig = [[OEXFacebookConfig alloc] initWithDictionary:dictionary];
    return facebookConfig;
}

@end