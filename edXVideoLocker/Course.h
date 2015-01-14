//
//  Course.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LatestUpdates.h"
@interface Course : NSObject

@property (nonatomic , strong) LatestUpdates *latest_updates;
@property (nonatomic , strong) NSString *start;
@property (nonatomic , strong) NSString *course_image_url;
@property (nonatomic , strong) NSString *end;
@property (nonatomic , strong) NSString *name;
@property (nonatomic , strong) NSString *org;
@property (nonatomic , strong) NSString *video_outline;
@property (nonatomic , strong) NSString *course_id;
@property (nonatomic , strong) NSString *number;
@property (nonatomic , strong) NSString *course_updates;    //  ANNOUNCEMENTS
@property (nonatomic , strong) NSString *course_handouts;   //  HANDOUTS
@property (nonatomic , strong) NSString *course_about;      // COURSE INFO
@property (nonatomic , assign) BOOL isStartDateOld;
@property (nonatomic , assign) BOOL isEndDateOld;

@property (nonatomic , strong) NSData *imageDataCourse;
@end
