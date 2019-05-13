//
//  OEXSegmentConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSegmentConfig.h"

static NSString* const OEXSegmentIOConfigKey = @"SEGMENT_IO";

@implementation OEXSegmentConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _apiKey = dictionary[@"SEGMENT_IO_WRITE_KEY"];
        _enabled = [dictionary[@"ENABLED"] boolValue] && _apiKey;
    }
    return self;
}

@end

@implementation OEXConfig (Segment)

- (OEXSegmentConfig*)segmentConfig {
    NSDictionary* dictionary = [self objectForKey:OEXSegmentIOConfigKey];
    OEXSegmentConfig* segmentConfig = [[OEXSegmentConfig alloc] initWithDictionary:dictionary];
    return segmentConfig;
}

@end
