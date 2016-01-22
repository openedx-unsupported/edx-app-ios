//
//  NSObject+OEXReplaceNull.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

/// Recursively traverses a data structure through arrays
/// and dictionaries replacing NSNull instances with the empty string
/// Should only be used on valid JSON types
@interface NSObject (OEXReplaceNull)

- (instancetype)oex_replaceNullsWithEmptyStrings;

@end

NS_ASSUME_NONNULL_END
