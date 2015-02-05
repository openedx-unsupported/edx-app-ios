//
//  OEXRouter.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXCourse;

@interface OEXRouter : NSObject

/// Note that this is not thread safe. The expectation is that this only happens
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedRouter:(OEXRouter*)router;
+ (instancetype)sharedRouter;

- (void)showCourse:(OEXCourse*)course fromController:(UIViewController*)controller;

@end
