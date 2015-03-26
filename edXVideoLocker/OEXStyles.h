//
//  OEXStyles.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/3/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OEXStyles : NSObject

/// Note that these are not thread safe. The expectation is that these operations are done
/// immediately when the app launches or synchronously at the start of a test.
+ (instancetype)sharedStyles;
+ (void)setSharedStyles:(OEXStyles*)styles;

- (UIFont*)sansSerifOfSize:(CGFloat)size;
- (UIFont*)boldSansSerifOfSize:(CGFloat)size;

- (NSString*)styleHTMLContent:(NSString*)htmlString;

@end
