//
//  OEXFacebookConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXFacebookConfig : NSObject
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
@property(nonatomic, copy) NSString* appId;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end

@interface OEXConfig (Facebook)

@property (nullable, readonly, strong, nonatomic) OEXFacebookConfig* facebookConfig;

@end

NS_ASSUME_NONNULL_END
