//
//  OEXCourse.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourse.h"

#import "NSDate+OEXComparisons.h"
#import "NSMutableDictionary+OEXSafeAccess.h"
#import "OEXDateFormatting.h"
#import "OEXLatestUpdates.h"
#import "OEXCoursewareAccess.h"

OEXStartType OEXStartTypeForString(NSString* type) {
    NSDictionary* startTypes = @{
                                 @"string" : @(OEXStartTypeString),
                                 @"timestamp" : @(OEXStartTypeTimestamp),
                                 @"empty" : @(OEXStartTypeNone)
                                 };
    NSNumber* result = [startTypes objectForKey:type] ?: @(OEXStartTypeNone);
    return result.integerValue;
}

NSString* NSStringForOEXStartType(OEXStartType type) {
    switch(type) {
    case OEXStartTypeString: return @"string";
    case OEXStartTypeTimestamp: return @"timestamp";
    case OEXStartTypeNone: return @"empty";
    }
}

@interface OEXCourseStartDisplayInfo ()

@property (strong, nonatomic, nullable) NSDate* date;
@property (copy, nonatomic, nullable) NSString* displayDate;
@property (assign, nonatomic) OEXStartType type;

@end

@implementation OEXCourseStartDisplayInfo

- (id)initWithDate:(NSDate *)date displayDate:(NSString *)displayDate type:(OEXStartType)type {
    self = [super init];
    if(self != nil) {
        self.date = date;
        self.displayDate = displayDate;
        self.type = type;
    }
    return self;
}

- (NSDictionary<NSString*, id>*)jsonFields {
    NSMutableDictionary<NSString*, NSObject*>* result = [[NSMutableDictionary alloc] init];
    [result setObjectOrNil:[OEXDateFormatting serverStringWithDate:self.date] forKey:@"start"];
    [result setObjectOrNil:self.displayDate forKey:@"start_display"];
    [result setObjectOrNil:NSStringForOEXStartType(self.type) forKey:@"start_type"];
    return result;
}

@end

@interface OEXCourse ()

@property (nonatomic, strong) OEXLatestUpdates* latest_updates;
@property (nonatomic, strong) NSDate* end;
@property (nonatomic, strong) OEXCourseStartDisplayInfo* start_display_info;
@property (nonatomic, copy) NSString* course_image_url;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* org;
@property (nonatomic, copy) NSString* video_outline;
@property (nonatomic, copy) NSString* course_id;
@property (nonatomic, copy) NSString* root_block_usage_key;
@property (nonatomic, copy) NSString* subscription_id;
@property (nonatomic, copy) NSString* number;
@property (nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (nonatomic, copy) NSString* course_about;           // COURSE INFO
@property (nonatomic, strong) OEXCoursewareAccess* courseware_access;
@property (nonatomic, copy) NSString* discussionUrl;
@property (nonatomic, copy) NSString* certificateUrl;

@end

@implementation OEXCourse

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if(self != nil) {
        self.end = [OEXDateFormatting dateWithServerString:[info objectForKey:@"end"]];
        
        NSDate* start = [OEXDateFormatting dateWithServerString:[info objectForKey:@"start"]];
        self.start_display_info = [[OEXCourseStartDisplayInfo alloc]
                                   initWithDate:start
                                   displayDate:[info objectForKey:@"start_display"]
                                   type:OEXStartTypeForString([info objectForKey:@"start_type"])];
        self.course_image_url = [info objectForKey:@"course_image"];
        self.name = [info objectForKey:@"name"];
        self.org = [info objectForKey:@"org"];
        self.video_outline = [info objectForKey:@"video_outline"];
        self.course_id = [info objectForKey:@"id"];
        self.root_block_usage_key = [info objectForKey:@"root_block_usage_key"];
        self.number = [info objectForKey:@"number"];
        self.course_updates = [info objectForKey:@"course_updates"];
        self.course_handouts = [info objectForKey:@"course_handouts"];
        self.course_about = [info objectForKey:@"course_about"];
        self.subscription_id = [info objectForKey:@"subscription_id"];
        NSDictionary* accessInfo = [info objectForKey:@"courseware_access"];
        self.courseware_access = [[OEXCoursewareAccess alloc] initWithDictionary: accessInfo];
        NSDictionary* updatesInfo = [info objectForKey:@"latest_updates"];
        self.latest_updates = [[OEXLatestUpdates alloc] initWithDictionary:updatesInfo];
        self.discussionUrl = [info objectForKey:@"discussion_url"];

    }
    return self;
}

- (BOOL)isStartDateOld {
    return [self.start_display_info.date oex_isInThePast];
}

- (BOOL)isEndDateOld {
    return [self.end oex_isInThePast];
}

@end
