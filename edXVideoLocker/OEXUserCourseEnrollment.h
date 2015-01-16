//
//  OEXUserCourseEnrollment.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 05/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXCourse.h"

@interface OEXUserCourseEnrollment : NSObject

@property (nonatomic , strong) NSString *created;
@property (nonatomic , strong) NSString *mode;
@property (nonatomic , assign) BOOL is_active;
@property (nonatomic , strong) OEXCourse *course;

@end
