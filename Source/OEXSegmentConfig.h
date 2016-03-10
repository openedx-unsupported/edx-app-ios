//
//  OEXSegmentConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXSegmentConfig : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property(nonatomic, copy, nullable) NSString* apiKey;
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;

@end

@interface OEXConfig (Segment)

@property (readonly, nullable, strong, nonatomic) OEXSegmentConfig* segmentConfig;

@end

NS_ASSUME_NONNULL_END
