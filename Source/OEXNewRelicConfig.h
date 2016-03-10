//
//  OEXNewRelicConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXNewRelicConfig : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
@property(nonatomic, copy, nullable) NSString* apiKey;

@end

@interface OEXConfig (NewRelic)

@property (nullable, readonly, nonatomic, strong) OEXNewRelicConfig* newRelicConfig;

@end

NS_ASSUME_NONNULL_END
