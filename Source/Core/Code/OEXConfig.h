//
//  OEXConfig.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXFabricConfig;
@class OEXFacebookConfig;
@class OEXGoogleConfig;
@class OEXNewRelicConfig;
@class OEXParseConfig;
@class OEXSegmentConfig;
@class OEXZeroRatingConfig;

@interface OEXConfig : NSObject

@property (strong, nonatomic) NSDictionary* properties;

/// Note that this is not thread safe. The expectation is that this only happens
/// immediately when the app launches or synchronously at the start of a test.
+ (void)setSharedConfig:(OEXConfig*)config;
+ (instancetype)sharedConfig;

- (id)initWithAppBundleData;
- (id)initWithBundle:(NSBundle*)bundle;
- (id)initWithDictionary:(NSDictionary*)dictionary;

- (nullable id)objectForKey:(NSString*)key;
- (nullable NSString*)stringForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key;
- (BOOL)boolForKey:(NSString*)key defaultValue:(BOOL) defaultValue;

@end

// Name all the known configuration keys
// So it's easy to find them all
// Use a full method instead of a constant name for the key
// in case we need to do something clever in individual cases
@interface OEXConfig (OEXKnownConfigs)

// Debugging string for configuration name
- (NSString*)environmentName;
/// User facing platform name, like "edX"
- (NSString*)platformName;
/// User facing platform web destination, like "edx.org"
- (NSString*)platformDestinationName;
- (nullable NSString*)organizationCode;
// Network
- (nullable NSURL*)apiHostURL;
- (nullable NSString*)feedbackEmailAddress;
- (nullable NSString*)oauthClientID;

/** Feature flag for the debug menu */
- (BOOL)shouldShowDebug;

@end


@protocol OEXConfigProvider <NSObject>

@property (readonly, strong, nonatomic) OEXConfig* config;

@end

NS_ASSUME_NONNULL_END
