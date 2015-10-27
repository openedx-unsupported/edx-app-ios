//
//  OEXCourse+OEXTestDataFactory.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourse+OEXTestDataFactory.h"

static NSDictionary<NSString*, id>* OEXCourseBaseTestData() {
    // TODO: add more course properties as they become useful for testing
    NSString* courseID = [NSUUID UUID].UUIDString;
    NSURL* imagePath = [[NSBundle mainBundle] URLForResource:@"Splash_map" withExtension:@"png"];
    return @{
      @"id" : courseID,
      @"subscription_id" : [NSUUID UUID].UUIDString,
      @"name" : @"A Great Course",
      @"course_image" : imagePath.absoluteString,
      @"org" : @"edX",
      @"id" : @"123"
      };
}

@implementation OEXCourse (OEXTestDataFactory)


+ (instancetype)freshCourse {
    return [[OEXCourse alloc] initWithDictionary: OEXCourseBaseTestData()];
}

+ (instancetype)inaccessibleCourse {
    NSMutableDictionary<NSString*, id>* data = OEXCourseBaseTestData().mutableCopy;
    data[@"courseware_access"] = @{
                                  @"has_access" : @NO,
                                  };
    return [[OEXCourse alloc] initWithDictionary:data];
}

+ (instancetype)freshCourseWithDiscussionsEnabled : (BOOL) enabled {
    NSString* courseID = [NSUUID UUID].UUIDString;
    NSURL* imagePath = [[NSBundle mainBundle] URLForResource:@"Splash_map" withExtension:@"png"];
    
    NSDictionary* courseDictionary = @{
                                       @"id" : courseID,
                                       @"subscription_id" : [NSUUID UUID].UUIDString,
                                       @"name" : @"A Great Course",
                                       @"course_image" : imagePath.absoluteString,
                                       @"org" : @"edX",
                                       @"id" : @"123",
                                       };
    if (enabled) {
        [courseDictionary setValue:@"http://www.url.com" forKey: @"discussion_url"];
    }
    
    
    OEXCourse* course = [[OEXCourse alloc] initWithDictionary: courseDictionary];
    // TODO: add more course properties as they become useful for testing
    return course;
}

@end
