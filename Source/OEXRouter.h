//
//  OEXRouter.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DataManager;

@class RouterEnvironment;

@class OEXHelperVideoDownload;
@class OEXVideoPathEntry;
@class NetworkManager;

typedef NS_ENUM(NSUInteger, OEXSideNavigationState) {
    OEXSideNavigationStateHidden,
    OEXSideNavigationStateVisible,
};


/// Sent whenever the side navigation is shown or hidden. User info will contain OEXSideNavigationChangedStateKey
extern NSString* OEXSideNavigationChangedStateNotification;
/// NSNumber wrapping an OEXSideNavigationState representing the current state
extern NSString* OEXSideNavigationChangedStateKey;

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
- (id)initWithEnvironment:(RouterEnvironment*)environment NS_DESIGNATED_INITIALIZER;

- (void)openInWindow:(UIWindow*)window;

#pragma mark Presentation
- (void)presentViewController:(UIViewController*)controller completion:(void(^)(void))completion;

#pragma mark Logistration
- (void)showLoginScreenFromController:(UIViewController*)controller completion:(void(^)(void))completion;
- (void)showLoggedOutScreen;
- (void)showSignUpScreenFromController:(UIViewController*)controller;

#pragma mark Top Level
- (void)showContentStackWithRootController:(UIViewController*)controller animated:(BOOL)animated;
- (void)showMyVideos;
- (void)showMySettings;
- (void)showMyCourses;

#pragma mark Course Structure
- (void)showAnnouncementsForCourseWithID:(NSString*)courseID;
- (void)showCourse:(OEXCourse*)course fromController:(UIViewController*)controller;

#pragma mark Videos
- (void)showDownloadsFromViewController:(UIViewController*)controller;
- (void)showCourseVideoDownloadsFromViewController:(UIViewController*)controller forCourse:(OEXCourse*)course lastAccessedVideo:(OEXHelperVideoDownload*)video downloadProgress:(NSArray*)downloadProgress selectedPath:(NSArray*)path;
- (void)showVideoSubSectionFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(NSMutableArray*) courseData;
- (void)showGenericCoursesFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(NSArray*) courseData selectedChapter:(OEXVideoPathEntry*) chapter;

@end

// Only for use by OEXRouter+Swift until we can consolidate this and that into a Swift file
@interface OEXRouter (Private)

@property (readonly, strong, nonatomic) RouterEnvironment* environment;

@end

@interface OEXRouter (Testing)

// UIViewController list for the currently navigation hierarchy
- (NSArray*)t_navigationHierarchy;
- (BOOL)t_showingLogin;
- (BOOL)t_hasDrawerController;

@end