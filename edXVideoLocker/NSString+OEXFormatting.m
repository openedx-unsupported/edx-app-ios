//
//  NSString+OEXFormatting.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSString+OEXFormatting.h"

#import "NSBundle+OEXConveniences.h"

@implementation NSString (OEXFormatting)

- (NSString*)oex_uppercaseStringInCurrentLocale {
    return [self uppercaseStringWithLocale:[[NSBundle mainBundle] oex_displayLocale]];
}

@end
