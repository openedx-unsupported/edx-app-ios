//
//  OEXDateFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXDateFormatting.h"

@implementation OEXDateFormatting

+ (NSString *)formatSecondsAsVideoLength:(NSTimeInterval)totalSeconds
{
    int seconds = (int)totalSeconds % 60;
    int minutes = (int)(totalSeconds / 60) % 60;
    int hours = (int)(totalSeconds / 3600);
    
    if (hours==0) {
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    }
    else {
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
    }
}

+ (NSDate*)dateWithServerString:(NSString *)dateString {
    if(dateString == nil) {
        return nil;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    return [formatter dateFromString:dateString];
}

+ (NSString*)formatAsMonthDayString:(NSDate *)date {
    if(date == nil) {
        return nil;
    }
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMMM dd"];
    return [formatter stringFromDate:date];
}

+(NSString *)formatAsMonthDayYearString:(NSDate *)date{
    if(date == nil) {
        return nil;
    }
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@" MMMM dd, yyyy "];
    return [formater stringFromDate:date];
}

@end
