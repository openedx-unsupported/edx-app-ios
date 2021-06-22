#import <Foundation/Foundation.h>
#import "ABKInAppMessageHTMLBase.h"

/*
 * Braze Public API: ABKInAppMessageHTMLFull
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageHTMLFull : ABKInAppMessageHTMLBase

/*!
 * This property is the remote URL of the assets zip file.
 */
@property (strong, nonatomic, nullable) NSURL *assetsZipRemoteUrl;

@end
NS_ASSUME_NONNULL_END
