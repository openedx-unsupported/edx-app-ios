//
//  OEXNewRelicConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXNewRelicConfig.h"

static NSString* const OEXNewRelicConfigKey = @"NEW_RELIC";

@implementation OEXNewRelicConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[@"ENABLED"] boolValue];
        _apiKey = dictionary[@"NEW_RELIC_KEY"];
    }
    return self;
}
@end

@implementation OEXConfig (NewRelic)

- (OEXNewRelicConfig*)newRelicConfig {
    NSDictionary* dictionary = [self objectForKey:OEXNewRelicConfigKey];
    OEXNewRelicConfig* newRelicConfig = [[OEXNewRelicConfig alloc] initWithDictionary:dictionary];
    return newRelicConfig;
}

@end