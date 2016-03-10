//
//  OEXZeroRatingConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import "OEXConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXZeroRatingConfig : NSObject

- (instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property(readonly, nonatomic, assign, getter = isEnabled) BOOL enabled;
@property (readonly, nonatomic) NSArray<NSString*>* carriers;

@end

@interface OEXConfig (ZeroRating)

@property (readonly, nonatomic, strong, nullable) OEXZeroRatingConfig* zeroRatingConfig;

@end

NS_ASSUME_NONNULL_END
