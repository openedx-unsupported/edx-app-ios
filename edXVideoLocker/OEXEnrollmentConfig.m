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
static NSString* const OEXEnrollmentConfigSearchURLKey = @"COURSE_SEARCH_URL";
static NSString* const OEXEnrollmentConfigCourseInfoURLTemplateKey = @"COURSE_INFO_URL_TEMPLATE";
static NSString* const OEXEnrollmentConfigExternalCourseURLSearchKey = @"EXTERNAL_COURSE_SEARCH_URL";
@interface OEXEnrollmentConfig (){
    
}
@end

@implementation OEXEnrollmentConfig

-(instancetype)initWithDictionary:(NSDictionary *)dictionary{
    self = [super init];
    if (self) {
        _enabled = [[dictionary objectForKey:OEXEnrollmentConfigEnabledKey] boolValue];
        _searchURL = [dictionary objectForKey:OEXEnrollmentConfigSearchURLKey];
        _courseInfoURLTemplate = [dictionary objectForKey:OEXEnrollmentConfigCourseInfoURLTemplateKey];
        _externalSearchURL=[dictionary objectForKey:OEXEnrollmentConfigExternalCourseURLSearchKey];
    }
    return self;
}

@end
