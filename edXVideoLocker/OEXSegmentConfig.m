//
//  OEXSegmentConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSegmentConfig.h"

@implementation OEXSegmentConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _enabled=[dictionary[@"ENABLED"] boolValue];
        _apiKey=dictionary[@"SEGMENT_IO_WRITE_KEY"];
    }
    return self;
}
@end
