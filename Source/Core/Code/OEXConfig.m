//
//  OEXConfig.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014-2015 edX. All rights reserved.
//

#import "OEXConfig.h"

#import <edXCore/edXCore-Swift.h>

// Please keep sorted alphabetically
static NSString* const OEXAPIHostURL = @"API_HOST_URL";
static NSString* const OEXEnvironmentDisplayName = @"ENVIRONMENT_DISPLAY_NAME";
static NSString* const OEXPlatformName = @"PLATFORM_NAME";
static NSString* const OEXPlatformDestinationName = @"PLATFORM_DESTINATION_NAME";
static NSString* const OEXFeedbackEmailAddress = @"FEEDBACK_EMAIL_ADDRESS";
static NSString* const OEXOrganizationCode = @"ORGANIZATION_CODE";

static NSString* const OEXOAuthClientID = @"OAUTH_CLIENT_ID";

// Debug
static NSString* const OEXDebugEnabledKey = @"SHOW_DEBUG";

static OEXConfig* sSharedConfig;

@implementation OEXConfig

+ (void)setSharedConfig:(OEXConfig*)config {
    sSharedConfig = config;
}

+ (instancetype)sharedConfig {
    return sSharedConfig;
}

- (id)initWithAppBundleData {
    self = [self initWithBundle:[NSBundle mainBundle]];
    return self;
}

- (id)initWithBundle:(NSBundle*)bundle {
    NSString* path = [bundle pathForResource:@"config" ofType:@"plist"];
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
    if(getenv(key.UTF8String)) {
        NSString* value = @(getenv(key.UTF8String));
        NSError* error = nil;
        id result = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
        if(error == nil && result) {
            return result;
        }
        else {
            [Logger logError:@"CONFIG" :[NSString stringWithFormat:@"Couldn't read config key (%@) from environment. Invalid JSON: %@", key, value] file:@"" __FILE__ line:__LINE__];
        }
    }
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

- (BOOL)boolForKey:(NSString*)key defaultValue:(BOOL) defaultValue {
    if (![_properties objectForKey:key]) {
        return defaultValue;
    }
    
    return [self boolForKey:key];
}

@end

@implementation OEXConfig (OEXKnownConfigs)

- (NSURL*)apiHostURL {
    return [NSURL URLWithString:[self stringForKey:OEXAPIHostURL]];
}

- (NSString*)environmentName {
    // This is for debug display, so if we don't have it, it makes sense to return the empty string
    return [self stringForKey:OEXEnvironmentDisplayName] ?: @"";
}

- (NSString*)platformName {
    return [self stringForKey:OEXPlatformName] ?: @"My open edX instance";
}

- (NSString*)platformDestinationName {
    return [self stringForKey:OEXPlatformDestinationName] ?: @"example.com";
}

- (NSString*)organizationCode {
    return [self stringForKey:OEXOrganizationCode];
}

- (NSString*)feedbackEmailAddress {
    return [self stringForKey: OEXFeedbackEmailAddress];
}

- (NSString*)oauthClientID {
    return [self stringForKey:OEXOAuthClientID];
}

#pragma mark - Debug

- (NSString *)debugDescription {
    return self.properties.description;
}

- (BOOL)shouldShowDebug {
#if DEBUG
    return [self boolForKey:OEXDebugEnabledKey];
#else 
    return false;
#endif
}

@end
