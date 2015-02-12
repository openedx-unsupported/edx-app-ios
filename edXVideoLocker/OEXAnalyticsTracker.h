//
//  OEXAnalyticsTracker.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 2/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXAnalyticsEvent;
@class OEXUserDetails;

@protocol OEXAnalyticsTracker <NSObject>

- (void)identifyUser:(OEXUserDetails*)user;
- (void)clearIdentifiedUser;

- (void)trackEvent:(OEXAnalyticsEvent*)event forComponent:(NSString*)component withProperties:(NSDictionary*)properties;

- (void)trackScreenWithName:(NSString*)screenName;

@end