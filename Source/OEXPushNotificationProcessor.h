//
//  OEXPushNotificationProcessor.h
//  edX
//
//  Created by Akiva Leffert on 4/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXPushListener.h"

@class OEXAnalytics;
@class OEXRouter;

@interface OEXPushNotificationProcessorEnvironment : NSObject

- (id)initWithAnalytics:(OEXAnalytics*)analytics router:(OEXRouter*)router;

@property (readonly, strong, nonatomic) OEXAnalytics* analytics;
@property (readonly, strong, nonatomic) OEXRouter* router;

@end

// Processes received push notifications, typically by showing appropriate UI
@interface OEXPushNotificationProcessor : NSObject <OEXPushListener>

- (id)initWithEnvironment:(OEXPushNotificationProcessorEnvironment*)environment;

@end

@interface OEXPushNotificationProcessor (Testing)

/// Returns a test userInfo dictionary with the expected format for new announcement notifications
- (NSDictionary*)t_announcementUserInfoWithCourseName:(NSString*)courseName courseID:(NSString*)courseID;
/// Returns a test userInfo dictionary with the expected format for some supported notification. 
- (NSDictionary*)t_exampleKnownActionUserInfo;
/// Returns a test userInfo dictionary with the expected format for some unsupported notification.
- (NSDictionary*)t_exampleUnknownActionUserInfo;

@end