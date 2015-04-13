//
//  OEXDataParser.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXCourse;
@class OEXUserDetails;

@interface OEXDataParser : NSObject

/// @return Array of OEXVideoSummary
- (NSArray*)videoSummaryListWithData:(NSData*)receivedData;

/// @return Array of EDXAnnouncement
- (NSArray*)announcementsWithData:(NSData*)receivedData;

/// @return Array of OEXUserCourseEnrollment
- (NSArray*)userCourseEnrollmentsWithData:(NSData*)receivedData;

- (NSString*)handoutsWithData:(NSData*)receivedData;

- (OEXUserDetails*)userDetailsWithData:(NSData*)receivedData;

@end
