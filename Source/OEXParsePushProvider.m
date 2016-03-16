//
//  OEXParsePushProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Parse/Parse.h>
@import edXCore;

#import "OEXParsePushProvider.h"

#import "NSArray+OEXFunctional.h"
#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXInterface.h"
#import "OEXPushSettingsManager.h"
#import "OEXRemovable.h"

static NSString* OEXParsePreferredLanguageKey = @"preferredLanguage";
static NSString* OEXParsePreferredCountryKey = @"preferredCountry";

// Course info relevant to parse
@interface OEXParseCourseInfo : NSObject

@property (copy, nonatomic) NSString* courseID;
@property (copy, nonatomic) NSString* channelID;

@end

@implementation OEXParseCourseInfo
@end

@interface OEXParsePushProvider ()

@property (strong, nonatomic) id <OEXRemovable> courseChangeListener;
@property (strong, nonatomic) id <OEXRemovable> settingsChangeListener;
@property (strong, nonatomic) OEXPushSettingsManager* settingsManager;

/// Array of OEXParseCourseInfo*
@property (copy, nonatomic) NSArray* courseInfos;

@end

@implementation OEXParsePushProvider

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation* installation = [PFInstallation currentInstallation];
    [installation setDeviceTokenFromData:deviceToken];
    [installation setObject:[NSBundle mainBundle].oex_displayLanguage forKey:OEXParsePreferredLanguageKey];
    [installation setObject:[NSBundle mainBundle].oex_displayCountry forKey:OEXParsePreferredCountryKey];
    [installation saveEventually];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // Nothing useful to do so ignore
}

- (void)sessionStartedWithUserDetails:(OEXUserDetails *)user settingsManager:(OEXPushSettingsManager *)settingsManager {
    self.settingsManager = settingsManager;
    self.courseChangeListener = [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXCourseListChangedNotification action:^(NSNotification *notification, OEXParsePushProvider* observer, id<OEXRemovable> removable) {
        NSArray* courseList = notification.userInfo[OEXCourseListKey];
        [observer courseListChangedToCourses:courseList];
    }];
    
    self.settingsChangeListener = [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXPushSettingsChangedNotification action:^(NSNotification *notification, OEXParsePushProvider* observer, id<OEXRemovable> removable) {
        [observer updateChannels];
    }];
}

- (void)sessionEnded {
    PFInstallation* installation = [PFInstallation currentInstallation];
    installation.deviceToken = @"";
    installation.channels = @[];
    [installation saveEventually];

    [self.courseChangeListener remove];
    self.courseChangeListener = nil;
    
    [self.settingsChangeListener remove];
    self.settingsChangeListener = nil;
}

- (void)updateChannels {
    if(self.courseInfos != nil) {
        PFInstallation* installation = [PFInstallation currentInstallation];
        installation.channels = [self.courseInfos oex_map:^id(OEXParseCourseInfo* info) {
            return [self.settingsManager isPushDisabledForCourseWithID:info.courseID] ? nil : info.channelID;
        }];
        [installation saveEventually];
    }
}

- (void)courseListChangedToCourses:(NSArray*)courses {
    self.courseInfos = [courses oex_map:^id(OEXCourse* course) {
        OEXParseCourseInfo* info = [[OEXParseCourseInfo alloc] init];
        info.courseID = course.course_id;
        info.channelID = course.subscription_id;
        return info;
    }];

    [self updateChannels];
}

- (void)pushSettingsChanged {
    [self updateChannels];
}

@end
