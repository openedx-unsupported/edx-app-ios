//
//  OEXMockAnalyticsTracker.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/27/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXAnalyticsTracker.h"

/// NOTE: These classes are deprecated. In Swift code use "MockAnalyticsTracker"

NS_ASSUME_NONNULL_BEGIN

@class OEXUserDetails;

@interface OEXMockAnalyticsEventRecord : NSObject

@property (strong, nonatomic) OEXAnalyticsEvent* event;
@property (strong, nonatomic) NSString* component;
@property (copy, nonatomic) NSDictionary* properties;

@end

@interface OEXMockAnalyticsScreenRecord : NSObject

@property (copy, nonatomic) NSString* screenName;
@property (copy, nonatomic, nullable) NSString* value;
@property (copy, nonatomic, nullable) NSString* courseID;
@property (copy, nonatomic, nullable) NSDictionary* additionalInfo;

@end

@interface OEXMockAnalyticsTracker : NSObject <OEXAnalyticsTracker>

@property (strong, nonatomic, nullable) OEXUserDetails* currentUser;

/// List of observed (OEXMockAnalyticsRecord or OEXMockAnalyticsScreenRecord) in order by time
@property (copy, nonatomic, readonly) NSArray* observedEvents;

@end

NS_ASSUME_NONNULL_END
