//
//  OEXConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXConfig.h"

#import "OEXEnrollmentConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXFabricConfig.h"
#import "OEXNewRelicConfig.h"
#import "OEXParseConfig.h"
#import "OEXSegmentConfig.h"
#import "OEXZeroRatingConfig.h"

// Please keep sorted alphabetically
static NSString* const OEXAPIHostURL = @"API_HOST_URL";
static NSString* const OEXEnvironmentDisplayName = @"ENVIRONMENT_DISPLAY_NAME";
static NSString* const OEXFacebookAppID = @"FACEBOOK_APP_ID";
static NSString* const OEXFeedbackEmailAddress = @"FEEDBACK_EMAIL_ADDRESS";
static NSString* const OEXOAuthClientSecret = @"OAUTH_CLIENT_SECRET";
static NSString* const OEXOAuthClientID = @"OAUTH_CLIENT_ID";
static NSString* const OEXPushNotificationsKey = @"PUSH_NOTIFICATIONS";

static NSString* const OEXDiscussionsEnabledKey = @"DISCUSSIONS_ENABLED";

// Composite configurations keys
static NSString* const OEXCourseEnrollmentPropertiesKey = @"COURSE_ENROLLMENT";
static NSString* const OEXFabricConfigKey = @"FABRIC";
static NSString* const OEXFacebookConfigKey = @"FACEBOOK";
static NSString* const OEXGoogleConfigKey = @"GOOGLE";
static NSString* const OEXParseConfigKey = @"PARSE";
static NSString* const OEXNewRelicConfigKey = @"NEW_RELIC";
static NSString* const OEXSegmentIOConfigKey = @"SEGMENT_IO";
static NSString* const OEXZeroRatingConfigKey = @"ZERO_RATING";
@interface OEXConfig ()

@property (strong, nonatomic) NSDictionary* properties;

@end

static OEXConfig* sSharedConfig;

@implementation OEXConfig

+ (void)setSharedConfig:(OEXConfig*)config {
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

- (BOOL)boolForKey:(NSString*)key {
    return [[self objectForKey:key] boolValue];
}

@end

@implementation OEXConfig (OEXKnownConfigs)

- (NSString*)apiHostURL {
    return [self stringForKey:OEXAPIHostURL];
}

- (NSString*)environmentName {
    // This is for debug display, so if we don't have it, it makes sense to return the empty string
    return [self stringForKey:OEXEnvironmentDisplayName] ? : @"";
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

- (NSString*)oauthClientSecret {
    return [self stringForKey:OEXOAuthClientSecret];
}

- (NSString*)oauthClientID {
    return [self stringForKey:OEXOAuthClientID];
}

- (BOOL)pushNotificationsEnabled {
    return [self boolForKey:OEXPushNotificationsKey];
}

- (OEXEnrollmentConfig*)courseEnrollmentConfig {
    NSDictionary* courseEnrollmentDictionary = [self objectForKey:OEXCourseEnrollmentPropertiesKey];
    OEXEnrollmentConfig* courseEnrollmentConfig = [[OEXEnrollmentConfig alloc] initWithDictionary:courseEnrollmentDictionary];
    return courseEnrollmentConfig;
}

- (OEXFacebookConfig*)facebookConfig {
    NSDictionary* dictionary = [self objectForKey:OEXFacebookConfigKey];
    OEXFacebookConfig* facebookConfig = [[OEXFacebookConfig alloc] initWithDictionary:dictionary];
    return facebookConfig;
}

- (OEXGoogleConfig*)googleConfig {
    NSDictionary* dictionary = [self objectForKey:OEXGoogleConfigKey];
    OEXGoogleConfig* googleConfig = [[OEXGoogleConfig alloc] initWithDictionary:dictionary];
    return googleConfig;
}

- (OEXFabricConfig*)fabricConfig {
    NSDictionary* dictionary = [self objectForKey:OEXFabricConfigKey];
    OEXFabricConfig* fabricConfig = [[OEXFabricConfig alloc] initWithDictionary:dictionary];
    return fabricConfig;
}

- (OEXParseConfig*)parseConfig {
    NSDictionary* dictionary = [self objectForKey:OEXParseConfigKey];
    OEXParseConfig* parseConfig = [[OEXParseConfig alloc] initWithDictionary:dictionary];
    return parseConfig;
}

- (OEXNewRelicConfig*)newRelicConfig {
    NSDictionary* dictionary = [self objectForKey:OEXNewRelicConfigKey];
    OEXNewRelicConfig* newRelicConfig = [[OEXNewRelicConfig alloc] initWithDictionary:dictionary];
    return newRelicConfig;
}

- (OEXSegmentConfig*)segmentConfig {
    NSDictionary* dictionary = [self objectForKey:OEXSegmentIOConfigKey];
    OEXSegmentConfig* segmentConfig = [[OEXSegmentConfig alloc] initWithDictionary:dictionary];
    return segmentConfig;
}

- (OEXZeroRatingConfig*)zeroRatingConfig {
    NSDictionary* dictionary = [self objectForKey:OEXZeroRatingConfigKey];
    OEXZeroRatingConfig* zeroRatingConfig = [[OEXZeroRatingConfig alloc] initWithDictionary:dictionary];
    return zeroRatingConfig;
}

+ (UIColor*)iconBlueColor {
    return [UIColor colorWithRed:0.106 green:0.643 blue:0.882 alpha:1.00];
}

+ (UIColor*)textBlueColor {
    return [UIColor colorWithRed:0.106 green:0.643 blue:0.882 alpha:1.00];
}

+ (UIColor*)iconGreyColor {
    return [UIColor colorWithRed:0.596 green:0.596 blue:0.596 alpha:1.00];
}

+ (UIColor*)textGreyColor {
    return [UIColor colorWithRed:0.596 green:0.596 blue:0.596 alpha:1.00];
}

+ (UIColor *)iconGreenColor {
    return [UIColor colorWithRed:0.525 green:0.722 blue:0.318 alpha:1.00];
}

+ (UIColor*)footerGreyColor {
    return [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1.00];
}

- (BOOL)shouldEnableNewCourseNavigation {
    return YES;
}

- (BOOL)shouldEnableDiscussions {
    return [self boolForKey:OEXDiscussionsEnabledKey];
}

@end