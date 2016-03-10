//
//  OEXGoogleConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXGoogleConfig.h"

static NSString* const OEXGoogleConfigKey = @"GOOGLE";

@interface OEXGoogleConfig () {
    BOOL _enabled;
}

@end

@implementation OEXGoogleConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[@"ENABLED"] boolValue];
        _apiKey = dictionary[@"GOOGLE_PLUS_KEY"];
    }
    return self;
}

- (BOOL)isEnabled
{
    //In order for Google+ To work, the API Key must also be set. 
    return _enabled && _apiKey != nil;
}

@end

@implementation OEXConfig (Google)

- (OEXGoogleConfig*)googleConfig {
    NSDictionary* dictionary = [self objectForKey:OEXGoogleConfigKey];
    OEXGoogleConfig* googleConfig = [[OEXGoogleConfig alloc] initWithDictionary:dictionary];
    return googleConfig;
}

@end
