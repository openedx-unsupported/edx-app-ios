//
//  OEXParseConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXParseConfig.h"

static NSString* const OEXParseConfigKey = @"PARSE";

@implementation OEXParseConfig

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        self.notificationsEnabled = [dictionary[@"NOTIFICATIONS_ENABLED"] boolValue];
        self.clientKey = dictionary[@"CLIENT_KEY"];
        self.applicationID = dictionary[@"APPLICATION_ID"];
    }
    return self;
}

@end

@implementation OEXConfig (Parse)

- (OEXParseConfig*)parseConfig {
    NSDictionary* dictionary = [self objectForKey:OEXParseConfigKey];
    OEXParseConfig* parseConfig = [[OEXParseConfig alloc] initWithDictionary:dictionary];
    return parseConfig;
}


@end