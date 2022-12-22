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
