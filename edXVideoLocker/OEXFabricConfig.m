//
//  OEXFabricConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFabricConfig.h"

@implementation OEXFabricConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self=[super init];
    if(self){
        _enabled=[dictionary[@"ENABLED"] boolValue];
        _appKey=dictionary[@"FABRIC_KEY"];
        _buildSecret=dictionary[@"FABRIC_BUILD_SECRET"];
    }
    return self;
}
@end
