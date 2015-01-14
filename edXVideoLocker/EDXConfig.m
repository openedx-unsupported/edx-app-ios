//
//  EDXConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "EDXConfig.h"

// Please keep sorted alphabetically
static NSString* const EDXAPIHostURL = @"API_HOST_URL";
static NSString* const EDXCourseSearchURL = @"COURSE_SEARCH_URL";
static NSString* const EDXFabricKey = @"FABRIC_KEY";
static NSString* const EDXEnvironmentDisplayName = @"ENVIRONMENT_DISPLAY_NAME";
static NSString* const EDXFacebookAppID = @"FACEBOOK_APP_ID";
static NSString* const EDXFeedbackEmailAddress = @"FEEDBACK_EMAIL_ADDRESS";
static NSString* const EDXGooglePlusKey = @"GOOGLE_PLUS_KEY";
static NSString* const EDXNewRelicKey = @"NEW_RELIC_KEY";
static NSString* const EDXOAuthClientSecret = @"OAUTH_CLIENT_SECRET";
static NSString* const EDXOAuthClientID = @"OAUTH_CLIENT_ID";
static NSString* const EDXSegmentIOWriteKey = @"SEGMENT_IO_WRITE_KEY";

@interface EDXConfig ()

@property (strong, nonatomic) NSDictionary* properties;

@end

@implementation EDXConfig

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


@implementation EDXConfig (EDXKnownConfigs)

- (NSString*)apiHostURL {
    return [self stringForKey:EDXAPIHostURL];
}

- (NSString*)courseSearchURL {
    return [self stringForKey:EDXCourseSearchURL];
}

- (NSString*)environmentName {
    // This is for debug display, so if we don't have it, it makes sense to return the empty string
    return [self stringForKey:EDXEnvironmentDisplayName] ?: @"";
}

- (NSString*)fabricKey {
    return [self stringForKey:EDXFabricKey];
}


- (NSString*)facebookURLScheme {
    NSString* fbID = [self stringForKey:EDXFacebookAppID];
    if(fbID) {
        return [NSString stringWithFormat:@"fb%@", fbID];
    }
    else {
        return nil;
    }
}

- (NSString*)feedbackEmailAddress {
    return [self stringForKey: EDXFeedbackEmailAddress];
}

- (NSString*)googlePlusKey {
    return [self stringForKey:EDXGooglePlusKey];
}

- (NSString*)oauthClientSecret {
    return [self stringForKey:EDXOAuthClientSecret];
}

- (NSString*)oauthClientID {
    return [self stringForKey:EDXOAuthClientID];
}

- (NSString*)segmentIOKey {
    return [self stringForKey:EDXSegmentIOWriteKey];
}

- (NSString*)newRelicKey {
    return [self stringForKey:EDXNewRelicKey];
}

@end