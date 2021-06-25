#import <Foundation/Foundation.h>
#import "ABKInAppMessageHTMLBase.h"

/*
 * Braze Public API: ABKInAppMessageHTML
 */
NS_ASSUME_NONNULL_BEGIN
@interface ABKInAppMessageHTML : ABKInAppMessageHTMLBase

/*!
 * This property indicates whether the content was built by our platform.
 */
@property (nonatomic) BOOL trusted;

/*!
 * This property is an array of asset URLs that are used when generating the HTML.
 */
@property (strong, nonatomic, nullable) NSArray *assetUrls;

/*!
 * This property is a dictionary of other structured data that can be included with the in-app message.
 */
@property (strong, nonatomic, nullable) NSDictionary *messageFields;

@end
NS_ASSUME_NONNULL_END
