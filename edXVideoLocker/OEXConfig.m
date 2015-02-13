//
//  OEXConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXConfig.h"

// Please keep sorted alphabetically
static NSString* const OEXAPIHostURL = @"API_HOST_URL";
static NSString* const OEXCourseEnrollmentPropertiesKey = @"COURSE_ENROLLMENT";
static NSString* const OEXCourseSearchURL = @"COURSE_SEARCH_URL";
static NSString* const OEXFabricKey = @"FABRIC_KEY";
static NSString* const OEXEnvironmentDisplayName = @"ENVIRONMENT_DISPLAY_NAME";
static NSString* const OEXFacebookAppID = @"FACEBOOK_APP_ID";
static NSString* const OEXFeedbackEmailAddress = @"FEEDBACK_EMAIL_ADDRESS";
static NSString* const OEXGooglePlusKey = @"GOOGLE_PLUS_KEY";
static NSString* const OEXNewRelicKey = @"NEW_RELIC_KEY";
static NSString* const OEXOAuthClientSecret = @"OAUTH_CLIENT_SECRET";
static NSString* const OEXOAuthClientID = @"OAUTH_CLIENT_ID";
static NSString* const OEXSegmentIOWriteKey = @"SEGMENT_IO_WRITE_KEY";

@interface OEXConfig ()

@property (strong, nonatomic) NSDictionary* properties;

@end

static OEXConfig* sSharedConfig;

@implementation OEXConfig

+ (void)setSharedConfig:(OEXConfig *)config {
    sSharedConfig = config;
}

+ (instancetype)sharedConfig {
    return sSharedConfig;
}

- (id)initWithAppBundleData {
    NSString* path = [[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"];
    NSDictionary* dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSAssert(dict, @"Unable to load config.");
    self = [self initWithDictionary:dict];
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if(self != nil) {
        self.properties = dictionary;
    }
    return self;
}

- (id)objectForKey:(NSString*)key {
    return self.properties[key];
}

- (NSString*)stringForKey:(NSString*)key {
    NSString* value = [self objectForKey:key];
    NSAssert(value == nil || [value isKindOfClass:[NSString class]], @"Expecting string key");
    return value;
}

@end


@implementation OEXConfig (OEXKnownConfigs)

- (NSString*)apiHostURL {
    return [self stringForKey:OEXAPIHostURL];
}

- (NSString*)courseSearchURL {
    return [self stringForKey:OEXCourseSearchURL];
}

- (NSString*)environmentName {
    // This is for debug display, so if we don't have it, it makes sense to return the empty string
    return [self stringForKey:OEXEnvironmentDisplayName] ?: @"";
}

- (NSString*)fabricKey {
    return [self stringForKey:OEXFabricKey];
}


- (NSString*)facebookURLScheme {
    NSString* fbID = [self stringForKey:OEXFacebookAppID];
    if(fbID) {
        return [NSString stringWithFormat:@"fb%@", fbID];
    }
    else {
        return nil;
    }
}

- (NSString*)feedbackEmailAddress {
    return [self stringForKey: OEXFeedbackEmailAddress];
}

- (NSString*)googlePlusKey {
    return [self stringForKey:OEXGooglePlusKey];
}

- (NSString*)oauthClientSecret {
    return [self stringForKey:OEXOAuthClientSecret];
}

- (NSString*)oauthClientID {
    return [self stringForKey:OEXOAuthClientID];
}

- (NSString*)segmentIOKey {
    return [self stringForKey:OEXSegmentIOWriteKey];
}

- (NSString*)newRelicKey {
    return [self stringForKey:OEXNewRelicKey];
}

- (OEXEnrollmentConfig *)courseEnrollmentConfig{
    NSDictionary *courseEnrollmentDictionary = [self objectForKey:OEXCourseEnrollmentPropertiesKey];
    OEXEnrollmentConfig *courseEnrollmentConfig = [[OEXEnrollmentConfig alloc] initWithDictionary:courseEnrollmentDictionary];
    return courseEnrollmentConfig;
}

@end