//
//  OEXConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

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

- (id)objectForKey:(NSString*)key;
- (NSString*)stringForKey:(NSString*)key;

@end

// Name all the known configuration keys
// So it's easy to find them all
// Use a full method instead of a constant name for the key
// in case we need to do something clever in individual cases
@interface OEXConfig (OEXKnownConfigs)

- (NSString*)environmentName;

// Network
// TODO: Transition this to an actual NSURL
- (NSString*)apiHostURL;
- (NSString*)feedbackEmailAddress;
- (NSString*)oauthClientID;
- (NSString*)oauthClientSecret;
- (BOOL)pushNotificationsEnabled;

- (OEXEnrollmentConfig*)courseEnrollmentConfig;
- (OEXFabricConfig*)fabricConfig;
- (OEXFacebookConfig*)facebookConfig;
- (OEXGoogleConfig*)googleConfig;
- (OEXParseConfig*)parseConfig;
- (OEXNewRelicConfig*)newRelicConfig;
- (OEXSegmentConfig*)segmentConfig;
- (OEXZeroRatingConfig*)zeroRatingConfig;

// Color for the Icons in Courseware (selected)
+ (UIColor*)iconBlueColor;
+ (UIColor*)iconGreyColor;
+ (UIColor*)textGreyColor;
+ (UIColor*)iconGreenColor;

/// Feature Flag for under development redesign of course views. Will be removed once the feature is done
- (BOOL)shouldEnableNewCourseNavigation;

/// Feature Flag for under development discussion feature. Will be removed once the feature is done
/// at which point discussion control will be configured by the server
- (BOOL)shouldEnableDiscussions;

@end