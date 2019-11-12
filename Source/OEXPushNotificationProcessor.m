//
//  OEXPushNotificationProcessor.m
//  edX
//
//  Created by Akiva Leffert on 4/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXPushNotificationProcessor.h"
#import "edX-Swift.h"
#import "OEXAnalytics.h"
#import "NSString+OEXFormatting.h"
#import "OEXRouter.h"

typedef NS_ENUM(NSUInteger, OEXPushAction) {
    OEXPushActionUnknown,
    OEXPushActionAnnouncement
};

static NSString* const OEXPushActionKey = @"action";

static NSString* const OEXPushActionNameAnnouncement = @"course.announcement";
static NSString* const OEXPushAnnouncementCourseIDKey = @"course-id";
static NSString* const OEXPushAnnouncementCourseNameKey = @"course-name";

static NSString* const OEXPushSpawnStateKey = @"OEXPushSpawnStateKey";

@implementation OEXPushNotificationProcessorEnvironment

- (id)initWithAnalytics:(OEXAnalytics *)analytics router:(OEXRouter *)router {
    self = [super init];
    if(self != nil) {
        _analytics = analytics;
        _router = router;
    }
    return self;
}

@end

@interface OEXPushNotificationProcessor ()

@property (strong, nonatomic) OEXPushNotificationProcessorEnvironment* environment;

@end

@implementation OEXPushNotificationProcessor

- (id)initWithEnvironment:(OEXPushNotificationProcessorEnvironment*)environment {
    self = [super init];
    if(self != nil) {
        self.environment = environment;
    }
    return self;
}

- (OEXPushAction)actionWithString:(NSString*)action {
    static dispatch_once_t onceToken;
    static NSDictionary* actions;
    dispatch_once(&onceToken, ^{
        actions = @{
                    OEXPushActionNameAnnouncement : @(OEXPushActionAnnouncement)
                    };
    });
    return [actions[action] integerValue];
}

- (NSString*)bodyForAction:(OEXPushAction)action userInfo:(NSDictionary*)userInfo {
    switch (action) {
        case OEXPushActionUnknown:
            return @"";
            break;
        case OEXPushActionAnnouncement: {
            NSString* courseName = userInfo[OEXPushAnnouncementCourseNameKey];
            return [Strings courseAnnouncementNotificationBodyWithCourseName:courseName];
        }
        default:
            break;
    }
}

- (void)spawnLocalNotificationWithAction:(OEXPushAction)action userInfo:(NSDictionary*)userInfo {
    UILocalNotification* notification = [[UILocalNotification alloc] init];
    notification.userInfo = userInfo;
    
    notification.alertBody = [self bodyForAction:action userInfo:userInfo];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)handleNotificationActionWithUserInfo:(NSDictionary*)userInfo {
    NSString* actionName = userInfo[OEXPushActionKey];
    OEXPushAction action = [self actionWithString:actionName];
    switch (action) {
        case OEXPushActionAnnouncement: {
            NSString* courseID = userInfo[OEXPushAnnouncementCourseIDKey];
            [self.environment.analytics trackAnnouncementNotificationTappedWithCourseID:courseID];
            [self.environment.router showAnnouncementsForCourseWithID:courseID];
            break;
        }
        case OEXPushActionUnknown:
            // Unknown action - do nothing
            break;
    }
}

- (void)trackReceivedNotificationAnnouncementWithAction:(OEXPushAction)action userInfo:(NSDictionary*)userInfo {
    switch (action) {
        case OEXPushActionAnnouncement:
            [self.environment.analytics trackAnnouncementNotificationReceivedWithCourseID:userInfo[OEXPushAnnouncementCourseIDKey]];
            break;
            
        case OEXPushActionUnknown:
            break;
    }
}

- (void)didReceiveLocalNotificationWithUserInfo:(NSDictionary*)userInfo {
    [self handleNotificationActionWithUserInfo:userInfo];
}

- (void)didReceiveRemoteNotificationWithUserInfo:(NSDictionary*)userInfo {
    NSString* actionName = userInfo[OEXPushActionKey];
    OEXPushAction action = [self actionWithString:actionName];
    if(action != OEXPushActionUnknown) {
        [self trackReceivedNotificationAnnouncementWithAction:action userInfo:userInfo];
        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            // The application was active when we received the notification
            // so no alert will appear. TODO: show some in app UI
        }
        else {
            // We handle localization of notifications client side by receiving them as remote notifications and then
            // respawning them with localized strings as local notifications
            [self spawnLocalNotificationWithAction:action userInfo:userInfo];
        }
    }
    
}

@end

@implementation OEXPushNotificationProcessor (Testing)

- (NSDictionary*)t_announcementUserInfoWithCourseName:(NSString *)courseName courseID:(NSString *)courseID {
    return @{
             OEXPushActionKey : OEXPushActionNameAnnouncement,
             OEXPushAnnouncementCourseIDKey : courseID,
             OEXPushAnnouncementCourseNameKey : courseName
             };
}

- (NSDictionary*)t_exampleKnownActionUserInfo {
    return [self t_announcementUserInfoWithCourseName:@"some course" courseID:@"course id"];
}

- (NSDictionary*)t_exampleUnknownActionUserInfo {
    return @{ OEXPushActionKey : @"XXX UNKNOWN XXX DO NOTHING" };
}

@end
