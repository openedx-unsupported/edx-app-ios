//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXAppDelegate.h"

#import <Crashlytics/Crashlytics.h>
#import <Fabric/Fabric.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GooglePlus/GooglePlus.h>
#import <NewRelicAgent/NewRelic.h>
#import <SEGAnalytics.h>

#import "edX-Swift.h"
#import "Logger+OEXObjC.h"

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXFabricConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXGoogleSocial.h"
#import "OEXInterface.h"
#import "OEXNewRelicConfig.h"
#import "OEXPushProvider.h"
#import "OEXPushNotificationManager.h"
#import "OEXPushSettingsManager.h"
#import "OEXRouter.h"
#import "OEXSession.h"
#import "OEXSegmentConfig.h"

@interface OEXAppDelegate () <UIApplicationDelegate>

@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;
@property (nonatomic, strong) OEXEnvironment* environment;

@end

@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state.
    // dispatch_async so that the XCTest bundle (where TestEnvironmentBuilder lives) has already loaded
    dispatch_async(dispatch_get_main_queue(), ^{
        if(NSClassFromString(@"TestEnvironmentBuilder")) {
            id builder = NSClassFromString(@"TestEnvironmentBuilder");
            (void)[[builder alloc] init];
        }
    });
    return YES;
#endif

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];
    [self.environment.router openInWindow:self.window];

    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = false;
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
        if(handled) {
            return handled;
        }

    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
        [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    }
   
    return handled;
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.environment.pushNotificationManager didReceiveRemoteNotificationWithUserInfo:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self.environment.pushNotificationManager didReceiveLocalNotificationWithUserInfo:notification.userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [self.environment.pushNotificationManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self.environment.pushNotificationManager didFailToRegisterForRemoteNotificationsWithError:error];
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)())completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        OEXLogError(@"DOWNLOADS", @"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession:(NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        OEXLogInfo(@"DOWNLOADS", @"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

#pragma mark Environment

- (void)setupGlobalEnvironment {
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];

    OEXConfig* config = self.environment.config;

    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];

    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey]];
    }

    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }

    //Initialize Fabric
    OEXFabricConfig* fabric = [config fabricConfig];
    if(fabric.appKey && fabric.isEnabled) {
        [Fabric with:@[CrashlyticsKit]];
    }
    
    
}

@end
