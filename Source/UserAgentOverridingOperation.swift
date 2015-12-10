//
//  UserAgentGenerationOperation.swift
//  edX
//
//  Created by Akiva Leffert on 12/10/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

class UserAgentGenerationOperation : Operation {
    
    private let webView = WKWebView()
    private var resultStream = Sink<String>()
    
    override func performStart() {
        webView.evaluateJavaScript("navigator.userAgent") { (value, error) -> Void in
            let base = value as? String
            let bundle = NSBundle.mainBundle()
            let components = [bundle.oex_appName(), bundle.bundleIdentifier, bundle.oex_buildVersionString()].flatMap{ return $0 }
            let appPart = components.joinWithSeparator("/")
            let userAgent = (base.map { NSString(format: "%@ %@", $0, appPart) } ?? appPart) as String
            
            self.resultStream.send(userAgent)
        }
    }
    
    static func overrideUserAgent() {
        let operation = UserAgentGenerationOperation()
        operation.resultStream.extendLifetimeUntilFirstResult(success:
            { agent in
                NSUserDefaults.standardUserDefaults().registerDefaults(["UserAgent": agent])
            }, failure: {error in
                Logger.logError(NetworkManager.NETWORK, "Unable to load user agent: \(error.localizedDescription)")
            }
        )
        NSOperationQueue.mainQueue().addOperation(operation)
        
    }
}

