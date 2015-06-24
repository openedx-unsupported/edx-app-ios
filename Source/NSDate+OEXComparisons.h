//
//  NSDate+OEXComparions.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (OEXComparisons)

/// @return Whether the date is less than the current date as determined by [NSDate date]
- (BOOL)oex_isInThePast;

@end


@interface DateHelper : NSObject
+ (NSDateFormatter *)generalPurposeDateFormatter;
+ (NSString *)socialFormatFromDate:(NSDate *)date;

@end