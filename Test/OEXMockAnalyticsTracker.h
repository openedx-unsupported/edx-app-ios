//
//  OEXMockAnalyticsTracker.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXAnalyticsTracker.h"

@class OEXUserDetails;

@interface OEXMockAnalyticsEventRecord : NSObject

@property (strong, nonatomic) OEXAnalyticsEvent* event;
@property (strong, nonatomic) NSString* component;
@property (copy, nonatomic) NSDictionary* properties;

@end

@interface OEXMockAnalyticsScreenRecord : NSObject

@property (copy, nonatomic) NSString* screenName;

@end

@interface OEXMockAnalyticsTracker : NSObject <OEXAnalyticsTracker>

@property (strong, nonatomic) OEXUserDetails* currentUser;

/// List of observed (OEXMockAnalyticsRecord or OEXMockAnalyticsScreenRecord) in order by time
@property (copy, nonatomic, readonly) NSArray* observedEvents;

@end
