//
//  OEXDateFormatting.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXDateFormatting : NSObject

/// Formats a time interval for display as a video duration like 23:35 or 01:14:33
+ (NSString *)formatSecondsAsVideoLength:(NSTimeInterval)totalSeconds;

/// Format like April 11 or January 23
+ (NSString *)formatAsMonthDayString:(NSDate*)date;

/// Converts a string in standard ISO8601 format to a date
+ (NSDate*)dateWithServerString:(NSString*)dateString;

+(NSString *)formatAsMonthDayYearString:(NSDate *)date;
@end