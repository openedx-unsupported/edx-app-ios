//
//  NSDate+OEXComparions.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (OEXComparisons)

/// @return Whether the date is less than the current date as determined by [NSDate date]
- (BOOL)oex_isInThePast;

@end

NS_ASSUME_NONNULL_END
