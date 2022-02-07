#import <Foundation/Foundation.h>
#import "ABKSdkAuthenticationError.h"

/*
 * Braze Public API: ABKSdkAuthenticationDelegate
 */
NS_ASSUME_NONNULL_BEGIN

@protocol ABKSdkAuthenticationDelegate <NSObject>

/*!
 * This method is fired when an SDK Authentication error is returned by the server, for example, if
 * the signature is expired or invalid.
 *
 * You are responsible for providing the Braze SDK a valid signature when this delegate method is
 * called.
 * SDK requests will retry periodically using an exponential backoff approach. After 50 consecutive
 * failed attempts, retries will be paused until the next session start.
 *
 * @param authError The SDK Authentication error returned by the server
 */
- (void)handleSdkAuthenticationError:(ABKSdkAuthenticationError *)authError;

@end
NS_ASSUME_NONNULL_END
