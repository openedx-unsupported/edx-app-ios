//
//  OEXNewRelicConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXNewRelicConfig.h"

@implementation OEXNewRelicConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _enabled= [dictionary[@"ENABLED"] boolValue];
        _apiKey=dictionary[@"NEW_RELIC_KEY"];
    }
    return self;
}
@end
