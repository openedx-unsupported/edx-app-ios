//
//  OEXCourse+OEXTestDataFactory.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourse.h"

@interface OEXCourse (OEXTestDataFactory)

+ (instancetype)freshCourseWithDiscussionsEnabled : (BOOL) enabled;
+ (instancetype)freshCourse;
+ (instancetype)inaccessibleCourse;

@end
