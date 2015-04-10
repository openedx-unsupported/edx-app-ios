//
//  OEXCourse+OEXTestDataFactory.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourse+OEXTestDataFactory.h"

@implementation OEXCourse (OEXTestDataFactory)

+ (instancetype)freshCourse {
    OEXCourse* course = [[OEXCourse alloc] init];
    course.course_id = [NSUUID UUID].UUIDString;
    // TODO: add more course properties as they become useful for testing
    return course;
}

@end
