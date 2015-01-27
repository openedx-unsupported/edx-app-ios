//
//  OEXAppDelegate.m
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXAppDelegate.h"

#import <FacebookSDK/FacebookSDK.h>
#import <GooglePlus/GooglePlus.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "OEXDownloadManager.h"
#import "OEXAuthentication.h"
#import "OEXConfig.h"
#import "OEXCustomTabBarViewViewController.h"
#import "OEXEnvironment.h"
#import "OEXInterface.h"
#import "OEXFBSocial.h"
#import "OEXGoogleSocial.h"
#import <SEGAnalytics.h>

typedef void (^completionHandler)();

@interface OEXAppDelegate ()
@property(nonatomic,strong)NSMutableDictionary *dictCompletionHandler;
@end

@implementation OEXAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Segment IO initialization
    // If you want to see debug logs from inside the SDK.
    
    OEXConfig* config = [OEXEnvironment shared].config;
    NSString* segmentKey = [config segmentIOKey];
    if(segmentKey) {
        [SEGAnalytics debug:NO];
        
        // Setup the Analytics shared instance with your project's write key
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentKey]];
    }
    
    self.dict_VideoSummary = [[NSMutableDictionary alloc] init];
    
    //Rechability
    NSString* reachabilityHost = [[NSURLComponents alloc] initWithString:config.apiHostURL].host;
    self.reachability = [Reachability reachabilityWithHostName:reachabilityHost];
    [_reachability startNotifier];

    //NewRelic Initialization with edx key
    [NewRelicAgent enableCrashReporting:NO];
    [NewRelicAgent startWithApplicationToken:[config newRelicKey]];
    
    if ([config fabricKey]) {
        [Fabric with:@[CrashlyticsKit]];
    }

    return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if(!_isSocialURLDelegateCalled && _handleGoogleSchema)//Google
    {
         [[OEXGoogleSocial sharedInstance]clearHandler];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APP_ENTER_FOREGROUND object:self userInfo:nil];
    }else if(!_isSocialURLDelegateCalled && (![[OEXFBSocial sharedInstance] isLogin]&&_handleFacebookSchema))
    {
        [[OEXFBSocial sharedInstance]clearHandler];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APP_ENTER_FOREGROUND object:self userInfo:nil];
    }
    _isSocialURLDelegateCalled=NO;
    _isSocialMediaLogin=NO;
    _handleFacebookSchema=NO;
    _handleGoogleSchema=NO;
}

- (BOOL)application: (UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    
    if(_isSocialMediaLogin){
        NSString* fbScheme = [OEXEnvironment shared].config.facebookURLScheme;
        if ([[url scheme] isEqual:fbScheme])
        {
            _isSocialURLDelegateCalled=YES;
            
            return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
        }
        else
        {
            _isSocialURLDelegateCalled=YES;
            return [GPPURLHandler handleURL:url
                          sourceApplication:sourceApplication
                                 annotation:annotation];
        }
    }
    return NO;
}

#pragma mark Background Downloading

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler {
     dispatch_async(dispatch_get_main_queue(), ^{
         NSLog(@"Background Download completion handler got called");
         [OEXDownloadManager sharedManager];
         [self addCompletionHandler:completionHandler forSession:identifier];
//         [self presentNotification];
     });
    [OEXDownloadManager sharedManager];
    [self addCompletionHandler:completionHandler forSession:identifier];
    
   // self.backgroundSessionCompletionHandler = completionHandler;
}

- (void)addCompletionHandler:(void (^)())handler forSession:(NSString *)identifier
{
    if(_dictCompletionHandler){
        _dictCompletionHandler=[[NSMutableDictionary alloc] init];
    }
    if ([self.dictCompletionHandler objectForKey:identifier]) {
        NSLog(@"Error: Got multiple handlers for a single session identifier.  This should not happen.\n");
    }
    
    [self.dictCompletionHandler setObject:handler forKey:identifier];
    
}

- (void)callCompletionHandlerForSession: (NSString *)identifier
{
    completionHandler handler = [self.dictCompletionHandler objectForKey: identifier];
    if (handler) {
        [self.dictCompletionHandler removeObjectForKey: identifier];
        NSLog(@"Calling completion handler for session %@", identifier);
        //[self presentNotification];
        handler();
    }
}

- (void)deactivate {
    //ELog(@"deactivate appdelegate");

    self.dict_VideoSummary = [[NSMutableDictionary alloc] init];
}


@end
