//
// NRURLSessionTaskDelegateBase
// NewRelic
//
//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-monitoring for information
//    https://docs.newrelic.com/docs/release-notes/mobile-release-notes/xcframework-release-notes/ for release notes
//
//  Copyright © 2023 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//


/*******************************************************************************
 * When using NSURLSession with a delegate, the delegate property of NSURLSession
 * will return an NRURLSessionTaskDelegateBase. To access the original delegate
 * use the realDelegate property on the NRURLSessionTaskDelegateBase.
 * Apologies for the inconvenience.
 *******************************************************************************/

@interface NRURLSessionTaskDelegateBase : NSObject <NSURLSessionTaskDelegate,NSURLSessionDataDelegate>
@property (nonatomic, retain, readonly) id<NSURLSessionDataDelegate> realDelegate;
@end
