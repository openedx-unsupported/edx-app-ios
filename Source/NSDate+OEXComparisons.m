//
//  NSDate+OEXComparisons.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSDate+OEXComparisons.h"

@implementation NSDate (OEXComparisons)

- (BOOL)oex_isInThePast {
    NSDate* now = [NSDate date];
    return [now compare: self] == NSOrderedDescending;
}

@end



@implementation DateHelper : NSObject

// TODO: moved to its own file; consider using NSDateComponentsFormatter for iOS8; localization
+ (NSString *)socialFormatFromDate:(NSDate *)date {
    NSString* timeinfo;
    NSDate *currenttime = [NSDate date];
    int seconds = [currenttime timeIntervalSinceDate:date];
    if (seconds <= 0) timeinfo = @"a few seconds ago";
    else if (seconds < 10) timeinfo = [NSString stringWithFormat:@"%d second%@ ago", seconds, (seconds>1?@"s":@"")];
    else if (seconds < 50) timeinfo = @"a few seconds ago";
    else if (seconds < 110) timeinfo = @"about a minute ago";
    else if (seconds < 60*60) timeinfo = [NSString stringWithFormat:@"%d minute%@ ago", seconds/60, ((int)(seconds/60)>1?@"s":@"")];
    else if (seconds < 24*60*60) timeinfo = [NSString stringWithFormat:@"%d hour%@ ago", seconds/3600, ((int)(seconds/3600)>1?@"s":@"")];
    else if (seconds < 48*60*60) timeinfo = @"1 day ago";
    else if (seconds < 72*60*60) timeinfo = @"2 days ago";
    else if (seconds < 96*60*60) timeinfo = @"3 days ago";
    else if (seconds < 120*60*60) timeinfo = @"4 days ago";
    else if (seconds < 144*60*60) timeinfo = @"5 days ago";
    else if (seconds < 168*60*60) timeinfo = @"6 days ago";
    else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MMM dd, yyyy"];
        timeinfo = [dateFormatter stringFromDate:date];
    }
    return timeinfo;
}

@end