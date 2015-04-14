//
//  OEXCourse.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXLatestUpdates;

@interface OEXCourse : NSObject

- (id)initWithDictionary:(NSDictionary*)info;

// TODO: Rename these to CamelCase
@property (readonly, nonatomic, strong) OEXLatestUpdates* latest_updates;
@property (readonly, nonatomic, strong) NSDate* start;
@property (readonly, nonatomic, strong) NSDate* end;
@property (readonly, nonatomic, copy) NSString* course_image_url;
@property (readonly, nonatomic, copy) NSString* name;
@property (readonly, nonatomic, copy) NSString* org;
@property (readonly, nonatomic, copy) NSString* video_outline;
@property (readonly, nonatomic, copy) NSString* course_id;
@property (readonly, nonatomic, copy) NSString* channel_id;
@property (readonly, nonatomic, copy) NSString* number;
@property (readonly, nonatomic, copy) NSString* course_updates;         //  ANNOUNCEMENTS
@property (readonly, nonatomic, copy) NSString* course_handouts;        //  HANDOUTS
@property (readonly, nonatomic, copy) NSString* course_about;           // COURSE INFO


@property (readonly, nonatomic, assign) BOOL isStartDateOld;
@property (readonly, nonatomic, assign) BOOL isEndDateOld;

@end
