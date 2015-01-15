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

#import "DownloadManager.h"
#import "OEXAuthentication.h"
#import "EDXConfig.h"
#import "OEXCustomTabBarViewViewController.h"
#import "EDXEnvironment.h"
#import "OEXInterface.h"
#import "OEXFBSocial.h"
#import "OEXGoogleSocial.h"
#import <SEGAnalytics.h>

@implementation UIViewController (rotate)
-(BOOL)shouldAutorotate {
    return NO;
}
@end

@implementation UINavigationController (rotate)
-(BOOL)shouldAutorotate {
    return NO;
}
@end

typedef void (^completionHandler)();

@interface OEXAppDelegate ()
@property(nonatomic,strong)NSMutableDictionary *dictCompletionHandler;
@end

@implementation OEXAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.applicationIconBadgeNumber = 0;
    
    // Segment IO initialization
    // If you want to see debug logs from inside the SDK.
    
    EDXConfig* config = [EDXEnvironment shared].config;
    NSString* segmentKey = [config segmentIOKey];
    if(segmentKey) {
        [SEGAnalytics debug:NO];
        
        // Setup the Analytics shared instance with your project's write key
        [SEGAnalytics setupWithConfiguration:[SEGAnalyticsConfiguration configurationWithWriteKey:segmentKey]];
    }

    
    self.str_NAVTITLE  = [[NSMutableString alloc] init];
    self.str_HANDOUTS_URL  = [[NSMutableString alloc] init];
    self.str_ANNOUNCEMENTS_URL  = [[NSMutableString alloc] init];
    self.str_COURSE_OUTLINE_URL  = [[NSMutableString alloc] init];
    self.str_COURSE_ABOUT_URL  = [[NSMutableString alloc] init];
    
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


+ (NSString *)timeFormatted:(NSString *)totalSeconds
{
    int total = [totalSeconds intValue];
    
    int seconds = total % 60;
    int minutes = (total / 60) % 60;
    int hours = total / 3600;
    
    if (hours==0)
        return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
    else
        return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}



+ (NSString *)appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
}

- (NSString *)convertDate:(NSString *)strReceiveDate
{
    if ([strReceiveDate length]==0)
    {
        return @"";
    }
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSDate *date2 = [formater dateFromString:strReceiveDate];
    [formater setDateFormat:@"MMMM dd"];
    NSString *str_date = [formater stringFromDate:date2];
    return str_date;
}


- (BOOL)isDateOld:(NSString *)sentdate
{
    NSDate *now = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *str_date = [formatter stringFromDate:now];
    
    if ([str_date compare: sentdate] == NSOrderedDescending) // Left Operand is greater than right operand.
        return YES;
    else
        return NO;
}


+ (BOOL)isEmailValid:(NSString *)str_email
{
    
    // Regular expression to checl the email format.
    NSString *emailReg = @".+@.+\\.[A-Za-z]+";
    
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailReg];
    if (![str_email isEqualToString:@""])
    {
        if ([emailTest evaluateWithObject:str_email] != YES)
        {
            return NO;
        }
        else
        {
            return YES;
        }
    }
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    [self.locationManager startUpdatingLocation];

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.applicationIconBadgeNumber = 0;
}



- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

}

- (BOOL)application: (UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    
    if(_isSocialMediaLogin){
        NSString* fbScheme = [EDXEnvironment shared].config.facebookURLScheme;
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
         [DownloadManager sharedManager];
         [self addCompletionHandler:completionHandler forSession:identifier];
//         [self presentNotification];
     });
    [DownloadManager sharedManager];
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

    [self.str_NAVTITLE setString:@""];
    [self.str_HANDOUTS_URL setString:@""];
    [self.str_ANNOUNCEMENTS_URL setString:@""];
    [self.str_COURSE_OUTLINE_URL setString:@""];
    [self.str_COURSE_ABOUT_URL setString:@""];
    self.dict_VideoSummary = [[NSMutableDictionary alloc] init];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
