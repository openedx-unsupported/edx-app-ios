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

@property (nonatomic, strong) NSDictionary *courseEnrollmentDictionary;

@end

@implementation OEXEnrollmentConfig

+ (instancetype)sharedEnrollmentConfig {
    static dispatch_once_t onceToken;
    static OEXEnrollmentConfig *sharedEnrollmentConfig = nil;
    dispatch_once(&onceToken, ^{
        sharedEnrollmentConfig = [[OEXEnrollmentConfig alloc] init];
    });
    return sharedEnrollmentConfig;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        OEXConfig* config = [OEXConfig sharedConfig];
        self.courseEnrollmentDictionary = [config courseEnrollmentProperties];
    }
    return self;
}

-(BOOL)enabled{
    return [[self.courseEnrollmentDictionary objectForKey:OEXEnrollmentConfigEnabledKey] boolValue];
}

-(NSString *)searchURL{
    return [self.courseEnrollmentDictionary objectForKey:OEXEnrollmentConfigSearchURLKey];
}

-(NSString *)courseInfoURLTemplate{
    return [self.courseEnrollmentDictionary objectForKey:OEXEnrollmentConfigCourseInfoURLTemplateKey];
}

@end
