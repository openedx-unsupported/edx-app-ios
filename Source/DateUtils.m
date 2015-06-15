//
//  DateUtils.m
//  edX
//
//  Created by Ehmad Zubair Chughtai on 15/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "DateUtils.h"

@implementation DateUtils

+ (NSString*)getFormattedDate {
    NSDate* date = [NSDate date];
    NSDateFormatter* format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"YYYY-MM-dd HH:mm:ss.SSSSSSZ"];
    NSString* strdate = [format stringFromDate:date];
    
    NSString* substringFirst = [strdate substringToIndex:29];
    NSString* substringsecond = [strdate substringFromIndex:29];
    strdate = [NSString stringWithFormat:@"%@:%@", substringFirst, substringsecond];
    return strdate;
}

@end
