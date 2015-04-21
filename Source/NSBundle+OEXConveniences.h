//
//  NSBundle+OEXConveniences.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/26/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (OEXConveniences)

- (NSString*)oex_shortVersionString;
- (NSLocale*)oex_displayLocale;
- (NSString*)oex_displayLanguage;

@end
