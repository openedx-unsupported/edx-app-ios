//
//  OEXCourse.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCourse.h"

#import "edX-Swift.h"

#import "NSDate+OEXComparisons.h"
#import "NSObject+OEXReplaceNull.h"
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
    [result setObjectOrNil:[DateFormatting serverStringWithDate:self.date] forKey:@"start"];
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
@property (nonatomic, copy) NSString* course_id;
@property (nonatomic, copy) NSString* root_block_usage_key;
@property (nonatomic, copy) NSString* subscription_id;
@property (nonatomic, copy) NSString* number;
@property (nonatomic, copy) NSString* effort;
@property (nonatomic, copy) NSString* short_description;
@property (nonatomic, copy) NSString* overview_html;
@property (nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (nonatomic, copy) NSString* course_about;           // COURSE INFO
@property (nonatomic) Boolean invitationOnly;
@property (nonatomic, strong) OEXCoursewareAccess* courseware_access;
@property (nonatomic, copy) NSString* discussionUrl;
@property (nonatomic, copy) NSDictionary<NSString*, CourseMediaInfo*>* mediaInfo;
@property (nonatomic, readwrite) CourseShareUtmParameters *courseShareUtmParams;

@end

@implementation OEXCourse

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if(self != nil) {
        info = [info oex_replaceNullsWithEmptyStrings];
        self.end = [DateFormatting dateWithServerString:[info objectForKey:@"end"] timeZoneIdentifier:NULL];
        
        NSDate* startDate = [DateFormatting dateWithServerString:[info objectForKey:@"start"] timeZoneIdentifier:NULL];
        self.start_display_info = [[OEXCourseStartDisplayInfo alloc]
                                   initWithDate:startDate
                                   displayDate:[info objectForKey:@"start_display"]
                                   type:OEXStartTypeForString([info objectForKey:@"start_type"])];
        self.course_image_url = [info objectForKey:@"course_image"];
        self.name = [info objectForKey:@"name"];
        self.org = [info objectForKey:@"org"];
        self.course_id = [info objectForKey:@"id"];
        self.root_block_usage_key = [info objectForKey:@"root_block_usage_key"];
        self.number = [info objectForKey:@"number"];
        self.effort = [info objectForKey:@"effort"];
        self.short_description = [info objectForKey:@"short_description"];
        self.overview_html = [info objectForKey:@"overview"];
        self.course_updates = [info objectForKey:@"course_updates"];
        self.course_handouts = [info objectForKey:@"course_handouts"];
        self.course_about = [info objectForKey:@"course_about"];
        self.subscription_id = [info objectForKey:@"subscription_id"];
        self.invitationOnly = [[info objectForKey:@"invitation_only"] boolValue];
        NSDictionary* accessInfo = [info objectForKey:@"courseware_access"];
        self.courseware_access = [[OEXCoursewareAccess alloc] initWithDictionary: accessInfo];
        NSDictionary* updatesInfo = [info objectForKey:@"latest_updates"];
        self.latest_updates = [[OEXLatestUpdates alloc] initWithDictionary:updatesInfo];
        self.discussionUrl = [info objectForKey:@"discussion_url"];
        NSDictionary* mediaInfo = OEXSafeCastAsClass(info[@"media"], NSDictionary);
        
        NSMutableDictionary<NSString*, CourseMediaInfo*>* parsedMediaInfo = [[NSMutableDictionary alloc] init];
        [mediaInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString* type = OEXSafeCastAsClass(key, NSString);
            NSDictionary* content = OEXSafeCastAsClass(obj, NSDictionary);
            CourseMediaInfo* info = [[CourseMediaInfo alloc] initWithDict:content];
            [parsedMediaInfo setObjectOrNil:info forKey:type];
        }];
        self.mediaInfo = parsedMediaInfo;
        NSDictionary *courseShareUtmParametersDictionary = [info objectForKey:@"course_sharing_utm_parameters"];
        self.courseShareUtmParams = [[CourseShareUtmParameters alloc] initWithParams:courseShareUtmParametersDictionary];
        
    }
    return self;
}

- (instancetype) initWithDictionary:(NSDictionary *)info auditExpiryDate:(nullable NSString *) auditExpiryDate {
    self.audit_expiry_date = [DateFormatting dateWithServerString:auditExpiryDate timeZoneIdentifier:NULL];
    return [self initWithDictionary:info];
}

- (BOOL)isStartDateOld {
    return [self.start_display_info.date oex_isInThePast];
}

- (BOOL)isEndDateOld {
    return [self.end oex_isInThePast];
}

- (BOOL) isAuditExpired {
    return [self.audit_expiry_date oex_isInThePast];
}

- (CourseMediaInfo*)courseImageMediaInfo {
    return self.mediaInfo[@"course_image"];
}

- (CourseMediaInfo*)courseVideoMediaInfo {
    return self.mediaInfo[@"course_video"];
}

- (NSString*)courseImageURL {
    return self.course_image_url ?: self.courseImageMediaInfo.uri;
}

@end
