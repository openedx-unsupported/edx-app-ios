//
//  OEXConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OEXEnrollmentConfig.h"
#import "OEXGoogleConfig.h"
#import "OEXFacebookConfig.h"
#import "OEXFabricConfig.h"
#import "OEXNewRelicConfig.h"
#import "OEXSegmentConfig.h"
#import "OEXZeroRatingConfig.h"
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
- (NSString*)apiHostURL;
- (NSString*)feedbackEmailAddress;
- (NSString*)oauthClientID;
- (NSString*)oauthClientSecret;

//Enrollment
- (OEXEnrollmentConfig*)courseEnrollmentConfig;
-(OEXFacebookConfig*)facebookConfig;
-(OEXGoogleConfig*)googleConfig;
-(OEXFabricConfig*)fabricConfig;
-(OEXNewRelicConfig*)newRelicConfig;
-(OEXSegmentConfig*)segmentConfig;
-(OEXZeroRatingConfig*)zeroRatingConfig;

@end