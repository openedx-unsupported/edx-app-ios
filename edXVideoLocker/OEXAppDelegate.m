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
#import <FacebookSDK/FacebookSDK.h>
#import <GooglePlus/GooglePlus.h>
#import <SEGAnalytics.h>

#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXDownloadManager.h"
#import "OEXEnvironment.h"
#import "OEXInterface.h"
#import "OEXFBSocial.h"
#import "OEXGoogleSocial.h"
#import <SEGAnalytics.h>
#import "OEXSession.h"

@interface OEXAppDelegate () <UIApplicationDelegate>

@property (nonatomic, strong) NSMutableDictionary* dictCompletionHandler;

@end

@implementation OEXAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
#if DEBUG
    // Skip all this initialization if we're running the unit tests
    // So they can start from a clean state
    if(NSClassFromString(@"XCTestCase")) {
        return YES;
    }
#endif
    [self setupGlobalEnvironment];
    [OEXSession migrateToKeychainIfNecessary];
	//// Clear keychain for first launch
    OEXSession* session = [OEXSession activeSession];
    NSString* userDir = [OEXFileUtility pathForUserNameCreatingIfNecessary:session.currentUser.username];
    BOOL hasUserDir = [[NSFileManager defaultManager] fileExistsAtPath:userDir];
    BOOL hasInvalidTokenType = session.edxToken.tokenType.length == 0;
    if(session != nil && (!hasUserDir || hasInvalidTokenType)) {
        [[OEXSession activeSession] closeAndClearSession];
    }
    return YES;
}

- (BOOL)application: (UIApplication*)application openURL:(NSURL*)url sourceApplication:(NSString*)sourceApplication annotation:(id)annotation {
    BOOL handled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    if(handled) {
        return handled;
    }
    handled = [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
    [[OEXGoogleSocial sharedInstance] setHandledOpenUrl:YES];
    return handled;
}

#pragma mark Background Downloading

- (void)application:(UIApplication*)application handleEventsForBackgroundURLSession:(NSString*)identifier
    completionHandler:(void (^)())completionHandler {
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString*)identifier {
    if(!_dictCompletionHandler) {
        _dictCompletionHandler = [[NSMutableDictionary alloc] init];
    }
    if([self.dictCompletionHandler objectForKey:identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    [self.dictCompletionHandler setObject:handler forKey:identifier];
}

- (void)callCompletionHandlerForSession: (NSString*)identifier {
    dispatch_block_t handler = [self.dictCompletionHandler objectForKey: identifier];
    if(handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        NSLog(@"Calling completion handler for session %@", identifier);
	//[self presentNotification];
        handler();
    }
}

-(void)setupGlobalEnvironment {
    OEXEnvironment* environment = [[OEXEnvironment alloc] init];
    [environment setupEnvironment];

	// Segment IO initialization
	// If you want to see debug logs from inside the SDK.
    OEXConfig* config = [OEXConfig sharedConfig];

	//Rechability
    NSString* reachabilityHost = [[NSURLComponents alloc] initWithString:config.apiHostURL].host;
    self.reachability = [Reachability reachabilityWithHostName:reachabilityHost];
    [_reachability startNotifier];

	//SegmentIO
    OEXSegmentConfig* segmentIO = [config segmentConfig];
    if(segmentIO.apiKey && segmentIO.isEnabled) {
        [SEGAnalytics debug:NO];
	// Setup the Analytics shared instance with your project's write key
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
