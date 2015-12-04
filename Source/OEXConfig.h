//
//  OEXConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BasicAuthCredential;
@class OEXEnrollmentConfig;
@class OEXFabricConfig;
@class OEXFacebookConfig;
@class OEXGoogleConfig;
@class OEXNewRelicConfig;
@class OEXParseConfig;
@class OEXSegmentConfig;
@class OEXZeroRatingConfig;

@interface OEXConfig : NSObject

/// Note that this is not thread safe. The expectation is that this only happens
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedConfig:(OEXConfig*)config;
+ (instancetype)sharedConfig;

- (id)initWithAppBundleData;
- (id)initWithDictionary:(NSDictionary*)dictionary;

- (nullable id)objectForKey:(NSString*)key;
- (nullable NSString*)stringForKey:(NSString*)key;

@end

// Name all the known configuration keys
// So it's easy to find them all
// Use a full method instead of a constant name for the key
// in case we need to do something clever in individual cases
@interface OEXConfig (OEXKnownConfigs)

// Debugging string for configuration name
- (nullable NSString*)environmentName;
/// User facing platform name, like "edX"
- (nonnull NSString*)platformName;
/// User facing platform web destination, like "edx.org"
- (nonnull NSString*)platformDestinationName;

// Network
- (nullable NSURL*)apiHostURL;
- (nullable NSString*)feedbackEmailAddress;
- (nullable NSString*)oauthClientID;
- (BOOL)pushNotificationsEnabled;
- (NSArray<BasicAuthCredential*>*)basicAuthCredentials;

- (nullable OEXEnrollmentConfig*)courseEnrollmentConfig;
- (nullable OEXFabricConfig*)fabricConfig;
- (nullable OEXFacebookConfig*)facebookConfig;
- (nullable OEXGoogleConfig*)googleConfig;
- (nullable OEXParseConfig*)parseConfig;
- (nullable OEXNewRelicConfig*)newRelicConfig;
- (nullable OEXSegmentConfig*)segmentConfig;
- (nullable OEXZeroRatingConfig*)zeroRatingConfig;

/// Feature Flag for under development discussion feature. Will be removed once the feature is done
/// at which point discussion control will be configured by the server
- (BOOL)shouldEnableDiscussions;

/// Feature Flag for under development user profiles. Will be removed once the feature is done.
- (BOOL)shouldEnableProfiles;

/// Feature Flag for under development certificate sharing. Will be removed once the feature is done.
- (BOOL)shouldEnableCertificates;

/** Feature Flag for under development course   sharing. Will be removed once the feature is done. */
- (BOOL)shouldEnableCourseSharing;

/** Feature flag for the debug menu */
- (BOOL)shouldShowDebug;

/** Last Used API host url */
@property (copy, nonatomic, nullable) NSURL* lastUsedAPIHostURL;

@end


NS_ASSUME_NONNULL_END