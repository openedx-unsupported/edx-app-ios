//
//  OEXParsePushProvider.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXParsePushProvider.h"

#import <Parse/Parse.h>

#import "NSArray+OEXFunctional.h"
#import "NSNotificationCenter+OEXSafeAccess.h"
#import "OEXInterface.h"
#import "OEXRemovable.h"

@interface OEXParsePushProvider ()

@property (strong, nonatomic) id <OEXRemovable> courseChangeListener;

@end

@implementation OEXParsePushProvider

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PFInstallation* installation = [PFInstallation currentInstallation];
    installation.deviceToken = [[NSString alloc] initWithData:deviceToken encoding:NSUTF8StringEncoding];
    [installation saveEventually];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // Nothing useful to do so ignore
}

- (void)sessionStartedWithUserDetails:(OEXUserDetails *)user {
    self.courseChangeListener = [[NSNotificationCenter defaultCenter] oex_addObserver:self notification:OEXCourseListChangedNotification action:^(NSNotification *notification, OEXParsePushProvider* observer, id<OEXRemovable> removable) {
        NSArray* courseList = notification.userInfo[OEXCourseListKey];
        [observer courseListChangedToCourses:courseList];
    }];
}

- (void)sessionEnded {
    PFInstallation* installation = [PFInstallation currentInstallation];
    installation.deviceToken = nil;
    installation.channels = @[];
    [installation saveEventually];

    [self.courseChangeListener remove];
    self.courseChangeListener = nil;
}

- (NSString*)channelForCourseID:(NSString*)courseID {
    // TODO: settle on a schema
    return courseID;
}

- (void)courseListChangedToCourses:(NSArray*)courseList {
    NSArray* courseIDs = [courseList oex_map:^id(OEXCourse* object) {
        return [self channelForCourseID:object.course_id];
    }];

    PFInstallation* installation = [PFInstallation currentInstallation];
    installation.channels = courseIDs;
    [installation saveEventually];
}


@end
