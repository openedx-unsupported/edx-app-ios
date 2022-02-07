#import <Foundation/Foundation.h>

/*
 * Braze Public API: ABKSdkAuthenticationError
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKSdkAuthenticationError : NSObject

/*!
 * The error code for the SDK Authentication failure.
 */
@property (readonly) NSInteger code;

/*!
 * The reason for the SDK Authentication failure.
 */
@property (nullable, readonly) NSString *reason;

/*!
 * The user ID associated with the request that failed due to SDK Authentication failure.
 */
@property (nullable, readonly) NSString *userId;

/*!
 * The signature that was sent with the request that failed due to SDK Authentication failure.
 */
@property (readonly) NSString *signature;

- (instancetype)initWithCode:(NSInteger)code
                      reason:(NSString *)reason
                      userId:(NSString *)userId
                   signature:(NSString *)signature;

@end
NS_ASSUME_NONNULL_END
