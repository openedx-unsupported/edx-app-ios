//
//  OEXRouter.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAnalytics;
@class OEXConfig;
@class OEXCourse;
@class OEXPushSettingsManager;
@class OEXStyles;

@interface OEXRouterEnvironment : NSObject

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
    pushSettingsManager:(OEXPushSettingsManager*)pushSettingsManager
                 styles:(OEXStyles*)styles;

@property (readonly, strong, nonatomic) OEXAnalytics* analytics;
@property (readonly, strong, nonatomic) OEXConfig* config;
@property (readonly, strong, nonatomic) OEXPushSettingsManager* pushSettingsManager;
@property (readonly, strong, nonatomic) OEXStyles* styles;

@end

@interface OEXRouter : NSObject

/// Note that this is not thread safe. The expectation is that this only happens
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedRouter:(OEXRouter*)router;
+ (instancetype)sharedRouter;

// Eventually the router should take all the dependencies of our view controllers and inject them during controller construction
- (id)initWithEnvironment:(OEXRouterEnvironment*)environment NS_DESIGNATED_INITIALIZER;

- (void)showCourse:(OEXCourse*)course fromController:(UIViewController*)controller;

- (void)showLoginScreenFromController:(UIViewController*)controller animated:(BOOL)animated;

- (void)showSignUpScreenFromController:(UIViewController*)controller animated:(BOOL)animated;

- (void)popAnimationFromBottomFromController:(UIViewController*)fromController;

- (void)pushAnimationFromBottomfromController:(UIViewController*)fromController toController:(UIViewController*)toController;

- (void)presentViewController:(UIViewController*)controller fromController:(UIViewController*)presenter;

@end
