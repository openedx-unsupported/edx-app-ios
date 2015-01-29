//
//  NSBundle+OEXConveniences.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSBundle+OEXConveniences.h"

@implementation NSBundle (OEXConveniences)

- (NSString *)oex_shortVersionString {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

@end
