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
@class OEXInterface;
@class OEXPushSettingsManager;
@class OEXSession;
@class OEXStyles;
@class OEXHelperVideoDownload;

@interface OEXRouterEnvironment : NSObject

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
              interface:(OEXInterface*)interface
    pushSettingsManager:(OEXPushSettingsManager*)pushSettingsManager
                session:(OEXSession*)session
                 styles:(OEXStyles*)styles;

@property (readonly, strong, nonatomic) OEXAnalytics* analytics;
@property (readonly, strong, nonatomic) OEXConfig* config;
@property (readonly, strong, nonatomic) OEXInterface* interface;
@property (readonly, strong, nonatomic) OEXPushSettingsManager* pushSettingsManager;
@property (readonly, strong, nonatomic) OEXSession* session;
@property (readonly, strong, nonatomic) OEXStyles* styles;

@end

/// Handles navigation and routing between screens
/// allowing view controllers to be discrete units not responsible for knowing what's around them
/// This makes it easier to change what classes are used for different screens and is a natural boundary for
/// controller testing.
///
/// If this gets long consider breaking it out into different subrouters e.g. login, course
@interface OEXRouter : NSObject

/// Note that this is not thread safe. The expectation is that this only happens
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedRouter:(OEXRouter*)router;
+ (instancetype)sharedRouter;

// Eventually the router should take all the dependencies of our view controllers and inject them during controller construction
- (id)initWithEnvironment:(OEXRouterEnvironment*)environment NS_DESIGNATED_INITIALIZER;

- (void)openInWindow:(UIWindow*)window;

- (void)showAnnouncementsForCourseWithID:(NSString*)courseID;
- (void)showCourse:(OEXCourse*)course fromController:(UIViewController*)controller;
- (void)showLoginScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion;
- (void)showLoggedOutScreen;
- (void)showSignUpScreenFromController:(UIViewController*)controller;
- (void)showDownloadsFromViewController:(UIViewController*)controller fromFrontViews:(BOOL)isFromFrontViews fromGenericView:(BOOL)isFromGenericViews;
- (void)showCourseVideoDownloadsFromViewController:(UIViewController*)controller forCourse:(OEXCourse*)course lastAccessedVideo:(OEXHelperVideoDownload*)video downloadProgress:(NSArray*)downloadProgress selectedPath:(NSArray*)path;

/// Presents the view modally. Meant as an indirection point so the controller isn't directly responsible for the presentation
- (void)presentViewController:(UIViewController*)controller fromController:(UIViewController*)presenter completion:(void(^)(void))completion;

@end


@interface OEXRouter (Testing)

// UIViewController list for the currently navigation hierarchy
- (NSArray*)t_navigationHierarchy;
- (BOOL)t_showingLogin;

@end