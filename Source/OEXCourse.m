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

@interface OEXCourse ()

@property (nonatomic, strong) OEXLatestUpdates* latest_updates;
@property (nonatomic, strong) NSDate* start;
@property (nonatomic, strong) NSDate* end;
@property (nonatomic, copy) NSString* course_image_url;
@property (nonatomic, copy) NSString* name;
@property (nonatomic, copy) NSString* org;
@property (nonatomic, copy) NSString* video_outline;
@property (nonatomic, copy) NSString* course_id;
@property (nonatomic, copy) NSString* channel_id;
@property (nonatomic, copy) NSString* number;
@property (nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (nonatomic, copy) NSString* course_about;           // COURSE INFO


@end

@implementation OEXCourse

- (id)initWithDictionary:(NSDictionary *)info {
    self = [super init];
    if(self != nil) {
        self.start = [OEXDateFormatting dateWithServerString:[info objectForKey:@"start"]];
        self.end = [OEXDateFormatting dateWithServerString:[info objectForKey:@"end"]];
        self.course_image_url = [info objectForKey:@"course_image"];
        self.name = [info objectForKey:@"name"];
        self.org = [info objectForKey:@"org"];
        self.video_outline = [info objectForKey:@"video_outline"];
        self.course_id = [info objectForKey:@"id"];
        self.number = [info objectForKey:@"number"];
        self.course_updates = [info objectForKey:@"course_updates"];
        self.course_handouts = [info objectForKey:@"course_handouts"];
        self.course_about = [info objectForKey:@"course_about"];
        self.channel_id = [info objectForKey:@"channel_id"];

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
