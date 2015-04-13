//
//  OEXParseConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXParseConfig.h"

@implementation OEXParseConfig

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        self.enabled = [dictionary[@"ENABLED"] boolValue];
        self.clientKey = dictionary[@"PARSE_CLIENT_KEY"];
        self.applicationID = dictionary[@"PARSE_APPLICATION_ID"];
    }
    return self;
}

@end
