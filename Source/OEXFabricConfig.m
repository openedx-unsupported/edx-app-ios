//
//  OEXFabricConfig.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXFabricConfig.h"

static NSString* const OEXFabricConfigKey = @"FABRIC";

@interface OEXFabricConfig ()
@property(nonatomic, copy) NSString* buildSecret;
@end

@implementation OEXFabricConfig

- (instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self) {
        _enabled = [dictionary[@"ENABLED"] boolValue];
        _appKey = dictionary[@"FABRIC_KEY"];
        _buildSecret = dictionary[@"FABRIC_BUILD_SECRET"];
        _kits = [[FabricKits alloc] initWithDictionary:dictionary[@"KITS"]];
        
    }
    return self;
}
@end

@implementation OEXConfig (Fabric)

- (OEXFabricConfig*)fabricConfig {
    NSDictionary* dictionary = [self objectForKey:OEXFabricConfigKey];
    OEXFabricConfig* fabricConfig = [[OEXFabricConfig alloc] initWithDictionary:dictionary];
    return fabricConfig;
}

@end
