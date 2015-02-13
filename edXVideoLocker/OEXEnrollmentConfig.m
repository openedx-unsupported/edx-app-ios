//
//  OEXEnrollmentConfig.m
//  edXVideoLocker
//
//  Created by Abhradeep on 11/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXEnrollmentConfig.h"
#import "OEXEnvironment.h"
#import "OEXConfig.h"

static NSString* const OEXEnrollmentConfigEnabledKey = @"ENABLED";
static NSString* const OEXEnrollmentConfigSearchURLKey = @"SEARCH_URL";
static NSString* const OEXEnrollmentConfigCourseInfoURLTemplateKey = @"COURSE_INFO_URL_TEMPLATE";

@interface OEXEnrollmentConfig (){
    
}

@end

@implementation OEXEnrollmentConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self = [super init];
    if (self) {
        self.enabled = [[dictionary objectForKey:OEXEnrollmentConfigEnabledKey] boolValue];
        self.searchURL = [dictionary objectForKey:OEXEnrollmentConfigSearchURLKey];
        self.courseInfoURLTemplate = [dictionary objectForKey:OEXEnrollmentConfigCourseInfoURLTemplateKey];
    }
    return self;
}

@end
