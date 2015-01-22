//
//  NSObject+OEXReplaceNull.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 04/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>


/// Recursively traverses a data structure through arrays
/// and dictionaries replacing NSNull instances with the empty string
/// Should only be used on valid JSON types
@interface NSObject (OEXReplaceNull)

- (instancetype)oex_replaceNullsWithEmptyStrings;

@end