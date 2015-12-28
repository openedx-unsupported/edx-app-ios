//
//  OEXRouter.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 1/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
- (id)initWithEnvironment:(nullable RouterEnvironment*)environment NS_DESIGNATED_INITIALIZER;

- (void)openInWindow:(nullable UIWindow*)window;

#pragma mark Presentation
- (void)presentViewController:(UIViewController*)controller completion:(nullable void(^)(void))completion;

#pragma mark Logistration
- (void)showLoginScreenFromController:(nullable UIViewController*)controller completion:(nullable void(^)(void))completion;
- (void)showLoggedOutScreen;
- (void)showSignUpScreenFromController:(nullable UIViewController*)controller;

#pragma mark Top Level
- (void)showContentStackWithRootController:(UIViewController*)controller animated:(BOOL)animated;
- (void)showMyVideos;
- (void)showMySettings;
- (void)showMyCourses;
- (void)showMyCoursesAnimated:(BOOL)animated pushingCourseWithID:(nullable NSString*)courseID;

#pragma mark Course Structure
- (void)showAnnouncementsForCourseWithID:(NSString*)courseID;

#pragma mark Videos
- (void)showDownloadsFromViewController:(UIViewController*)controller;
- (void)showCourseVideoDownloadsFromViewController:(UIViewController*)controller forCourse:(OEXCourse*)course lastAccessedVideo:(nullable OEXHelperVideoDownload*)video downloadProgress:(NSArray*)downloadProgress selectedPath:(NSArray*)path;
- (void)showVideoSubSectionFromViewController:(UIViewController*) controller forCourse:(OEXCourse*) course withCourseData:(nullable NSMutableArray*) courseData;
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

@protocol OEXRouterProvider <NSObject>

@property (readonly, nonatomic, weak, nullable) OEXRouter* router;

@end

NS_ASSUME_NONNULL_END

