//
//  OEXDataParser.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class OEXCourse;
@class OEXUserDetails;


// This class is deprecated. We prefer to have each model object have an initializer.
@interface OEXDataParser : NSObject

/// @return Array of OEXVideoSummary
- (NSArray*)videoSummaryListWithData:(NSData*)receivedData;

/// @return Array of OEXAnnouncement
- (NSArray*)announcementsWithData:(NSData*)receivedData;

/// @return Array of UserCourseEnrollment
- (NSArray*)userCourseEnrollmentsWithData:(NSData*)receivedData;

- (NSString*)handoutsWithData:(NSData*)receivedData;

- (OEXUserDetails*)userDetailsWithData:(NSData*)receivedData;

@end

NS_ASSUME_NONNULL_END