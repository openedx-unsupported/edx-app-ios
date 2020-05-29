//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

@import edXCore;
@import FirebaseAnalytics;
@import GoogleCast;
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <NewRelicAgent/NewRelic.h>
#import <Analytics/SEGAnalytics.h>
#import <Branch/Branch.h>
#import <Segment-GoogleAnalytics/SEGGoogleAnalyticsIntegrationFactory.h>
#import <Segment-Firebase/SEGFirebaseIntegrationFactory.h>
#import "OEXAppDelegate.h"
#import "edX-Swift.h"
#import "Logger+OEXObjC.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
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
#import <MSAL/MSAL.h>

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
    if([[NSProcessInfo processInfo].arguments containsObject:@"-UNIT_TEST"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            Class builder = NSClassFromString(@"TestEnvironmentBuilder");
            NSAssert(builder != nil, @"Can't find test environment builder");
            (void)[[builder alloc] init];
        });
        return YES;
    }
    if([[NSProcessInfo processInfo].arguments containsObject:@"-END_TO_END_TEST"]) {
        [[[OEXSession alloc] init] closeAndClearSession];
        [OEXFileUtility nukeUserData];
    }
#endif

    // logout user automatically if server changed
    [[[ServerChangedChecker alloc] init] logoutIfServerChanged];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Forcing app to run in Light mode because app isn't configured for dark mode
    if (@available(iOS 13.0, *)) {
        self.window.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    [self.window makeKeyAndVisible];

    [self setupGlobalEnvironment];
    [self.environment.session performMigrations];
    [self.environment.router openInWindow:self.window];
    [self configureBranch:launchOptions];
    [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    
    UIViewController *topController = self.window.rootViewController;
    
    return [topController supportedInterfaceOrientations];
}

// Respond to URI scheme links
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    // pass the url to the handle deep link call
    BOOL handled = false;
    if (self.environment.config.branchConfig.enabled) {
        handled = [[Branch getInstance] application:app openURL:url options:options];
        if (handled) {
            return handled;
        }
    }
    
    if (self.environment.config.facebookConfig.enabled) {
        handled = [[FBSDKApplicationDelegate sharedInstance] application:app openURL:url options:options];
        if (handled) {
            return handled;
        }
    }
    
    if (self.environment.config.googleConfig.enabled){
        handled = [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                          annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    
    if (self.environment.config.microsoftConfig.enabled) {
        handled = [MSALPublicClientApplication handleMSALResponse:url sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
    }

    return handled;
}

// Respond to Universal Links
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    
    if (self.environment.config.branchConfig.enabled) {
        return [[Branch getInstance] continueUserActivity:userActivity];
    }
    return NO;
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

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier completionHandler:(void (^)(void))completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)(void))handler forSession:(NSString*)identifier {
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
    [UserAgentOverrideOperation overrideUserAgentWithCompletion:nil];
    
    self.environment = [[OEXEnvironment alloc] init];
    [self.environment setupEnvironment];

    OEXConfig* config = self.environment.config;

    //Logging
    [DebugMenuLogger setup];

    //Rechability
    self.reachability = [[InternetReachability alloc] init];
    [_reachability startNotifier];

    //SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.isEnabled) {
        SEGAnalyticsConfiguration * configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:segmentIO.apiKey];
        
        //Segment to Google Analytics integration
        [configuration use:[SEGGoogleAnalyticsIntegrationFactory instance]];
        
        if (config.firebaseConfig.requiredKeysAvailable && config.firebaseConfig.isAnalyticsSourceSegment) {
            //Segment to Google Firebase integration
            [configuration use:[SEGFirebaseIntegrationFactory instance]];
        }
        
        [SEGAnalytics setupWithConfiguration:configuration];
    }
    //Initialize Firebase
    // Make Sure the google app id is valid before configuring firebase, the app can produce crash.
    //Firebase do not get exception with invalid google app ID, https://github.com/firebase/firebase-ios-sdk/issues/1581
    if (config.firebaseConfig.enabled && !config.firebaseConfig.isAnalyticsSourceSegment) {
        [FIRApp configure];
        [FIRAnalytics setAnalyticsCollectionEnabled:YES];
    }

    //NewRelic Initialization with edx key
    OEXNewRelicConfig* newrelic = [config newRelicConfig];
    if(newrelic.apiKey && newrelic.isEnabled) {
        [NewRelicAgent enableCrashReporting:NO];
        [NewRelicAgent startWithApplicationToken:newrelic.apiKey];
    }
    
    [self initilizeChromeCast];
}

- (void) initilizeChromeCast {
    // Ideally this should be in ChromeCastManager but
    // due to some weird SDK bug, chrome cast is not properly initializing from the swift classes.
    GCKDiscoveryCriteria *criteria = [[GCKDiscoveryCriteria alloc] initWithApplicationID: kGCKDefaultMediaReceiverApplicationID];
    GCKCastOptions *options = [[GCKCastOptions alloc] initWithDiscoveryCriteria:criteria];
    [GCKCastContext setSharedInstanceWithOptions:options];
    GCKCastContext.sharedInstance.useDefaultExpandedMediaControls = true;
    [ChromeCastManager.shared configureWithEnvironment:self.environment.router.environment];
}

- (void) configureBranch:(NSDictionary*) launchOptions {
    if (self.environment.config.branchConfig.enabled && self.environment.config.branchConfig.branchKey != nil) {
        [Branch setBranchKey:self.environment.config.branchConfig.branchKey];
        if ([Branch branchKey]){
            [[Branch getInstance] initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
                // params are the deep linked params associated with the link that the user clicked -> was re-directed to this app
                // params will be empty if no data found
                [[DeepLinkManager sharedInstance] processDeepLinkWith:params environment:self.environment.router.environment];
            }];
        }
    }
}

@end
