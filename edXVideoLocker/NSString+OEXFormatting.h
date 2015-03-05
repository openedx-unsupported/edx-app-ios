//
//  NSString+OEXFormatting.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (OEXFormatting)

/// Converts a string to UPPERCASE using the display locale
- (NSString*)oex_uppercaseStringInCurrentLocale;

@end
