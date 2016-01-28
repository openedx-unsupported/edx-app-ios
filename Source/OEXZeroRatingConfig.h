//
//  OEXZeroRatingConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 23/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXZeroRatingConfig : NSObject
@property(nonatomic, assign, getter = isEnabled) BOOL enabled;
- (NSArray*)carriers;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end

NS_ASSUME_NONNULL_END
