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
    NSString* courseID = [NSUUID UUID].UUIDString;
    NSURL* imagePath = [[NSBundle mainBundle] URLForResource:@"Splash_map" withExtension:@"png"];
    OEXCourse* course = [[OEXCourse alloc] initWithDictionary: @{
                                                                 @"id" : courseID,
                                                                 @"subscription_id" : [NSUUID UUID].UUIDString,
                                                                 @"name" : @"A Great Course",
                                                                 @"course_image" : imagePath.absoluteString,
                                                                 @"org" : @"edX",
                                                                 @"id" : @"123"
                                                                 }];
    // TODO: add more course properties as they become useful for testing
    return course;
}

@end
