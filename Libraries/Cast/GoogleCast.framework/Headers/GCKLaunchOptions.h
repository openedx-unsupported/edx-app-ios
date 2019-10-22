// Copyright 2014 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Receiver application launch options.
 */
GCK_EXPORT
@interface GCKLaunchOptions : NSObject <NSCopying, NSSecureCoding>

/** The sender's language code as per RFC 5646. The default is the sender device's language. */
@property(nonatomic, copy, nullable) NSString *languageCode;

/**
 * A flag indicating whether the receiver application should be relaunched if it is already
 * running. The default is <code>NO</code>.
 */
@property(nonatomic, assign) BOOL relaunchIfRunning;

/** Initializes the object with default values. */
- (instancetype)init;

/**
 * Initializes the object with the sender device's language code and the specified relaunch
 * behavior.
 */
- (instancetype)initWithRelaunchIfRunning:(BOOL)relaunchIfRunning;

/**
 * Designated initializer. Initializes the object with the specified language code and
 * relaunch behavior.
 *
 * @param languageCode The language code as per RFC 5646.
 * @param relaunchIfRunning A flag indicating whether the receiver application should be relaunched
 * if it is already running.
 */
- (instancetype)initWithLanguageCode:(nullable NSString *)languageCode
                   relaunchIfRunning:(BOOL)relaunchIfRunning;

@end

NS_ASSUME_NONNULL_END
