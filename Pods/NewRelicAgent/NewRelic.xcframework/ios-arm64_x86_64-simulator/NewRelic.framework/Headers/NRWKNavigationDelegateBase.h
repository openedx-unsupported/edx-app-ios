//  New Relic for Mobile -- iOS edition
//
//  See:
//    https://docs.newrelic.com/docs/mobile-monitoring for information
//    https://docs.newrelic.com/docs/release-notes/mobile-release-notes/xcframework-release-notes/ for release notes
//
//  Copyright © 2023 New Relic. All rights reserved.
//  See https://docs.newrelic.com/docs/licenses/ios-agent-licenses for license details
//
//  NRMAWKWebViewDelegateBase.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/17.
//  Copyright © 2023 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
//@protocol WKNavigationDelegate;

@interface NRWKNavigationDelegateBase : NSObject // <WKNavigationDelegate>
@property(weak, nullable) NSObject* realDelegate;

@end
