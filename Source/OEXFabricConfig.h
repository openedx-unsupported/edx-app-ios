//
//  OEXFabricConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"
#import "edX-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXFabricConfig : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property(nonatomic, copy, nullable) NSString* appKey;
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
@property (nullable, readonly, strong, nonatomic) FabricKits* kits;

@end


@interface OEXConfig (Fabric)

@property (nullable, readonly, strong, nonatomic) OEXFabricConfig* fabricConfig;

@end

NS_ASSUME_NONNULL_END

