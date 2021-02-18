//
//  NRMAWKWebViewDelegateBase.h
//  NewRelicAgent
//
//  Created by Bryce Buchanan on 1/5/17.
//  Copyright © 2017 New Relic. All rights reserved.
//

#import <Foundation/Foundation.h>
//@protocol WKNavigationDelegate;

@interface NRWKNavigationDelegateBase : NSObject // <WKNavigationDelegate>
@property(weak, nullable) NSObject* realDelegate;

@end
