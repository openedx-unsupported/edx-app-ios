//
//  OEXSegmentAnalyticsTracker.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 2/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <SEGAnalytics.h>

#import "OEXSegmentAnalyticsTracker.h"

#import "NSMutableDictionary+OEXSafeAccess.h"
#import "OEXAnalyticsData.h"
#import "OEXUserDetails.h"

static NSString* OEXSegmentAnalyticsGoogleCategoryKey = @"category";
static NSString* OEXSegmentAnalyticsGoogleLabelKey = @"label";

@implementation OEXSegmentAnalyticsTracker

- (void)identifyUser:(OEXUserDetails*)user {
    if(user.userId) {
        NSMutableDictionary* traits = [[NSMutableDictionary alloc] init];
        [traits setObjectOrNil:user.email forKey:key_email];
        [traits setObjectOrNil:user.username forKey:key_username];
        [[SEGAnalytics sharedAnalytics] identify:user.userId.description traits:traits];
    }
}

- (void)clearIdentifiedUser {
    [[SEGAnalytics sharedAnalytics] reset];
}

- (void)trackEvent:(OEXAnalyticsEvent*)event forComponent:(NSString*)component withProperties:(NSDictionary*)properties {
    NSMutableDictionary* context = @{}.mutableCopy;
    [context safeSetObject:value_app_name forKey:key_app_name];

    // These are optional depending on the event
    [context setObjectOrNil:component forKey:key_component];
    [context setObjectOrNil:event.courseID forKey:key_course_id];
    [context setObjectOrNil:event.openInBrowserURL forKey:key_open_in_browser];

    NSMutableDictionary* data = [[NSMutableDictionary alloc] initWithDictionary:properties];

    NSMutableDictionary* info = @{
        key_data : data,
        key_context : context,
        key_name : event.name
    }.mutableCopy;

    // These are specific to Google Analytics. Segment will pick them up automatically
    [info setObjectOrNil:event.category forKey:OEXSegmentAnalyticsGoogleCategoryKey];
    [info setObjectOrNil:event.label forKey:OEXSegmentAnalyticsGoogleLabelKey];

    [[SEGAnalytics sharedAnalytics] track:event.displayName properties:info];
}

- (void)trackScreenWithName:(NSString*)screenName {
    [[SEGAnalytics sharedAnalytics] screen:screenName properties:@{
         key_context : @{
             key_appname : value_appname
         }
     }];
}

@end
