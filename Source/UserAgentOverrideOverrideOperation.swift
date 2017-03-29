//
//  UserAgentOverrideOperation.swift
//  edX
//
//  Created by Akiva Leffert on 12/10/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

import edXCore

class UserAgentGenerationOperation : Operation {
    
    private let webView : WKWebView?
    private var resultStream = Sink<String>()
    
    override init() {
        if Thread.isMainThread {
            webView = WKWebView()
        }
        else {
            assertionFailure("User agent fetch operation must be created on the main thread")
            webView = nil
        }
        super.init()
    }
    
    static var appVersionDescriptor : String {
        let bundle = Bundle.main
        let components = [bundle.oex_appName(), bundle.bundleIdentifier, bundle.oex_buildVersionString()].flatMap{ return $0 }
        return components.joined(separator: "/")
    }
    
    override func performWithDoneAction(doneAction: @escaping () -> Void) {
        DispatchQueue.main.async { () -> Void in
            guard let webView = self.webView else {
                doneAction()
                return
            }
            
            webView.evaluateJavaScript("navigator.userAgent") { (value, error) -> Void in
                let base = value as? String
                let appPart = UserAgentGenerationOperation.appVersionDescriptor
                let userAgent = (base.map { (NSString(format: "%@ %@", $0, appPart) as String) } ?? appPart) as String
                self.resultStream.send(userAgent)
                doneAction()
            }
        }
    }
}

class UserAgentOverrideOperation : Operation {
    
    override func performWithDoneAction(doneAction: @escaping () -> Void) {
        DispatchQueue.main.async {
            let operation = UserAgentGenerationOperation()
            operation.resultStream.extendLifetimeUntilFirstResult(success:
                { agent in
                    NSUserDefaults.standardUserDefaults().registerDefaults(["UserAgent": agent])
                    doneAction()
                }, failure: {error in
                    Logger.logError(NetworkManager.NETWORK, "Unable to load user agent: \(error.localizedDescription)")
                    doneAction()
                }
            )
            OperationQueue.currentQueue?.addOperation(operation)
        }
        
    }
    
    @objc static func overrideUserAgent(completion : (() -> Void)? = nil) {
        let queue = OperationQueue()
        let operation = UserAgentOverrideOperation()
        operation.completionBlock = {
            dispatch_async(dispatch_get_main_queue()) {
                completion?()
            }
        }
        queue.addOperation(operation)
    }
}


extension UserAgentGenerationOperation {
    var t_resultStream : Stream<String> {
        return resultStream
    }
}
