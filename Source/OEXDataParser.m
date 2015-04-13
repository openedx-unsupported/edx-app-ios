//
//  OEXDataParser.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXDataParser.h"

#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"
#import "NSDate+OEXComparisons.h"
#import "NSObject+OEXReplaceNull.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAnnouncement.h"
#import "OEXCourse.h"
#import "OEXDateFormatting.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXLatestUpdates.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkInterface.h"
#import "OEXUserCourseEnrollment.h"
#import "OEXUserDetails.h"
#import "OEXVideoPathEntry.h"
#import "OEXVideoSummary.h"

@interface OEXDataParser ()
@property (nonatomic, weak) OEXInterface* dataInterface;
@end

@implementation OEXDataParser
- (id)initWithDataInterface:(OEXInterface*)dataInterface {
    self = [super init];
    self.dataInterface = dataInterface;
    return self;
}

- (NSArray*)announcementsWithData:(NSData*)receivedData {
    NSError* error;
    id array = [NSJSONSerialization oex_JSONObjectWithData:receivedData error:&error];
    if([array isKindOfClass:[NSArray class]]) {
        NSArray* announcements = [(NSArray*)array oex_replaceNullsWithEmptyStrings];
        return [announcements oex_map:^(NSDictionary* object) {
            return [[OEXAnnouncement alloc] initWithDictionary:object];
        }];
    }
    else {
        return [NSArray array];
    }
}

- (NSString*)handoutsWithData:(NSData*)receivedData {
    NSError* error;
    NSDictionary* dict = [NSJSONSerialization oex_JSONObjectWithData:receivedData error:&error];
    NSDictionary* dictResponse = nil;
    if([dict isKindOfClass:[NSDictionary class]]) {
        dictResponse = [dict oex_replaceNullsWithEmptyStrings];
    }
    if(!dictResponse || ![dictResponse objectForKey:@"handouts_html"]) {
        return @"<p>Sorry, There is currently no data available for this section</p>";;
    }
    NSString* htmlString = [dictResponse objectForKey:@"handouts_html"];
    return htmlString;
}

- (OEXUserDetails*)userDetailsWithData:(NSData*)receivedData {
    NSError* error;
    NSDictionary* dict = [NSJSONSerialization oex_JSONObjectWithData:receivedData error:&error];
    if(![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary* dictResponse = [dict oex_replaceNullsWithEmptyStrings];
    OEXUserDetails* obj_userdetails = [[OEXUserDetails alloc] init];
    obj_userdetails.userId = [dictResponse objectForKey:@"id"];
    obj_userdetails.username = [dictResponse objectForKey:@"username"];
    obj_userdetails.email = [dictResponse objectForKey:@"email"];
    obj_userdetails.name = [dictResponse objectForKey:@"name"];
    obj_userdetails.course_enrollments = [dictResponse objectForKey:@"course_enrollments"];
    obj_userdetails.url = [dictResponse objectForKey:@"url"];
    return obj_userdetails;
}

- (NSArray*)userCourseEnrollmentsWithData:(NSData*)receivedData {
    NSError* error;
    NSArray* arrResponse = [NSJSONSerialization oex_JSONObjectWithData:receivedData error:&error];
    NSMutableArray* arr_CourseEnrollmentObjetcs = [[NSMutableArray alloc] init];
    for(NSDictionary* dict in arrResponse) {
        // parse level - 1
        if(![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary* dictResponse = [dict oex_replaceNullsWithEmptyStrings];
        OEXUserCourseEnrollment* obj_usercourse = [[OEXUserCourseEnrollment alloc] init];
        obj_usercourse.created = [dictResponse objectForKey:@"created"];
        obj_usercourse.mode = [dictResponse objectForKey:@"mode"];
        obj_usercourse.is_active = [[dictResponse objectForKey:@"is_active"] boolValue];
        // Inner course dictionary parse

        // parse level - 2
        NSDictionary* dictCourse = [dictResponse objectForKey:@"course"];
        OEXCourse* obj_Course = [[OEXCourse alloc] init];
        obj_Course.start = [OEXDateFormatting dateWithServerString:[dictCourse objectForKey:@"start"]];
        obj_Course.end = [OEXDateFormatting dateWithServerString:[dictCourse objectForKey:@"end"]];
        obj_Course.course_image_url = [dictCourse objectForKey:@"course_image"];
        obj_Course.name = [dictCourse objectForKey:@"name"];
        obj_Course.org = [dictCourse objectForKey:@"org"];
        obj_Course.video_outline = [dictCourse objectForKey:@"video_outline"];
        obj_Course.course_id = [dictCourse objectForKey:@"id"];
        obj_Course.number = [dictCourse objectForKey:@"number"];
        obj_Course.course_updates = [dictCourse objectForKey:@"course_updates"];
        obj_Course.course_handouts = [dictCourse objectForKey:@"course_handouts"];
        obj_Course.course_about = [dictCourse objectForKey:@"course_about"];
        // assigning the object to memeber of its parent level object class
        obj_usercourse.course = obj_Course;
        // Inner LatestUpdate dictionary parse

        // parse level - 3
        NSDictionary* dictlatestupdate = [dictCourse objectForKey:@"latest_updates"];
        OEXLatestUpdates* obj_LatestUpdate = [[OEXLatestUpdates alloc] init];
        obj_LatestUpdate.video = [dictlatestupdate objectForKey:@"video"];
        // assigning the object to memeber of the parent level object class
        obj_Course.latest_updates = obj_LatestUpdate;
        // check start date is greater than current date
        NSDate* pastDate = [OEXDateFormatting dateWithServerString:[dictCourse objectForKey:@"start"]];
        obj_Course.isStartDateOld = [pastDate oex_isInThePast];
        if(obj_Course.end != nil) {
            NSDate* date = [OEXDateFormatting dateWithServerString:[dictCourse objectForKey:@"end"]];
            obj_Course.isEndDateOld = [date oex_isInThePast];
        }
        // array populated with objects and returned
        if(obj_usercourse.is_active) {
            [arr_CourseEnrollmentObjetcs addObject:obj_usercourse];
        }
    }
    return arr_CourseEnrollmentObjetcs;
}

- (NSArray*)videoSummaryListWithData:(NSData*)receivedData {
    NSMutableArray* arrSummary = [[NSMutableArray alloc] init];
    NSError* error;
    NSArray* arrResponse = [NSJSONSerialization oex_JSONObjectWithData:receivedData error:&error];
    for(NSDictionary* dict in arrResponse) {
        if(![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSDictionary* dictResponse = [dict oex_replaceNullsWithEmptyStrings];
        OEXVideoSummary* summaryList = [[OEXVideoSummary alloc] initWithDictionary:dictResponse];
        if(summaryList.chapterPathEntry.entryID != nil && summaryList.sectionPathEntry.entryID != nil) {
            [arrSummary addObject:summaryList];
        }
    }
    return arrSummary;
}
@end
