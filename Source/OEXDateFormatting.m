//
//  OEXDateFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXDateFormatting.h"

///The standard date format used all across the edX Platform.
static NSString* const dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

@implementation OEXDateFormatting

+ (NSString*)formatSecondsAsVideoLength:(NSTimeInterval)totalSeconds {
    int seconds = (int)totalSeconds % 60;
    int minutes = (int)(totalSeconds / 60) % 60;
    int hours = (int)(totalSeconds / 3600);

    if(hours == 0) {
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
    }
}

+ (NSDate*)dateWithServerString:(NSString*)dateString {
    if(dateString == nil) {
        return nil;
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    return [formatter dateFromString:dateString];
}


+ (NSDate*)dateWithGPlusBirthDate:(NSString*)dateString {
    if(dateString == nil) {
        return nil;
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter dateFromString:dateString];
}

+ (NSString*)formatAsMonthDayString:(NSDate*)date {
    if(date == nil) {
        return nil;
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM dd"];
    return [[formatter stringFromDate:date] uppercaseString];
}

+ (NSString*)formatAsMonthDayYearString:(NSDate*)date {
    if(date == nil) {
        return nil;
    }
    NSDateFormatter* formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@" MMMM dd, yyyy "];
    return [formater stringFromDate:date];
}

// example format : 2014-11-19T04:06:55Z
+ (NSString*)serverStringWithDate:(NSDate*)date {
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:dateFormat];
    [format setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSString* strdate = [format stringFromDate:date];

    return strdate;
}

@end
