//
//  OEXCourse.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourse.h"

#import "NSDate+OEXComparisons.h"
#import "OEXDateFormatting.h"
#import "OEXLatestUpdates.h"
#import "OEXCoursewareAccess.h"

@interface OEXCourse ()

@property (nonatomic, strong) OEXLatestUpdates* latest_updates;
@property (nonatomic, strong) NSDate* start;
@property (nonatomic, strong) NSDate* end;
@property (nonatomic, copy) NSString* start_display;
@property (nonatomic) OEXStartType start_type;
@property (nonatomic, copy) NSString* course_image_url;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* org;
@property (nonatomic, copy) NSString* video_outline;
@property (nonatomic, copy) NSString* course_id;
@property (nonatomic, copy) NSString* subscription_id;
@property (nonatomic, copy) NSString* number;
@property (nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (nonatomic, copy) NSString* course_about;           // COURSE INFO
@property (nonatomic, strong) OEXCoursewareAccess* courseware_access;

@end

@implementation OEXCourse

- (id)initWithDictionary:(NSDictionary *)info {
    NSDictionary* types = @{
                             @"string" : [NSNumber numberWithInt:OEXStartTypeString],
                             @"timestamp" : [NSNumber numberWithInt:OEXStartTypeTimestamp],
                             @"empty" : [NSNumber numberWithInt:OEXStartTypeNone]
                             };
    self = [super init];
    if(self != nil) {
        self.start = [OEXDateFormatting dateWithServerString:[info objectForKey:@"start"]];
        self.end = [OEXDateFormatting dateWithServerString:[info objectForKey:@"end"]];
        self.start_display = [info objectForKey:@"start_display"];
        NSString* start_type = [info objectForKey:@"start_type"];
        NSString* type = [types objectForKey:start_type];
        if(type != nil) {
            self.start_type = [type intValue];
        }
        else {
            self.start_type = OEXStartTypeNone;
        }
        self.course_image_url = [info objectForKey:@"course_image"];
        self.name = [info objectForKey:@"name"];
        self.org = [info objectForKey:@"org"];
        self.video_outline = [info objectForKey:@"video_outline"];
        self.course_id = [info objectForKey:@"id"];
        self.number = [info objectForKey:@"number"];
        self.course_updates = [info objectForKey:@"course_updates"];
        self.course_handouts = [info objectForKey:@"course_handouts"];
        self.course_about = [info objectForKey:@"course_about"];
        self.subscription_id = [info objectForKey:@"subscription_id"];
        NSDictionary* accessInfo = [info objectForKey:@"courseware_access"];
        self.courseware_access = [[OEXCoursewareAccess alloc] initWithDictionary: accessInfo];
        NSDictionary* updatesInfo = [info objectForKey:@"latest_updates"];
        self.latest_updates = [[OEXLatestUpdates alloc] initWithDictionary:updatesInfo];
    }
    return self;
}

- (BOOL)isStartDateOld {
    return [self.start oex_isInThePast];
}

- (BOOL)isEndDateOld {
    return [self.end oex_isInThePast];
}

@end
