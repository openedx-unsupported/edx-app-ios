//
//  OEXSegmentConfig.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 22/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXSegmentConfig : NSObject
@property(nonatomic, copy) NSString* apiKey;
@property(nonatomic, readonly, assign, getter = isEnabled) BOOL enabled;
- (instancetype)initWithDictionary:(NSDictionary*)dictionary;
@end

NS_ASSUME_NONNULL_END
