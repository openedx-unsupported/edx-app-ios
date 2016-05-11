//
//  OEXAnalyticsTracker.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 2/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXAnalyticsEvent;
@class OEXUserDetails;

@protocol OEXAnalyticsTracker <NSObject>

- (void)identifyUser:(nullable OEXUserDetails*)user;
- (void)clearIdentifiedUser;

- (void)trackEvent:(OEXAnalyticsEvent*)event forComponent:(nullable NSString*)component withProperties:(NSDictionary<NSString*, id>*)properties;

- (void)trackScreenWithName:(NSString*)screenName courseID:(nullable NSString*)courseID value:(nullable NSString*)value additionalInfo:(nullable NSDictionary<NSString*, NSString*>*) info;

@end

NS_ASSUME_NONNULL_END
