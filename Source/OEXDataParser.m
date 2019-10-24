//
//  OEXDataParser.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXDataParser.h"

#import "edX-Swift.h"

#import "NSArray+OEXFunctional.h"
#import "NSArray+OEXSafeAccess.h"
#import "NSDate+OEXComparisons.h"
#import "NSObject+OEXReplaceNull.h"
#import "NSJSONSerialization+OEXSafeAccess.h"

#import "OEXAnnouncement.h"
#import "OEXCourse.h"
#import "OEXHelperVideoDownload.h"
#import "OEXInterface.h"
#import "OEXLatestUpdates.h"
#import "OEXNetworkConstants.h"
#import "OEXNetworkInterface.h"
#import "OEXUserDetails.h"
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

@end
