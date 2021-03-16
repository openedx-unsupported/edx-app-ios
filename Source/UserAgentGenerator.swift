//
//  UserAgentGenerator.swift
//  edX
//
//  Created by Akiva Leffert on 12/10/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import WebKit

import edXCore

class UserAgentGenerator: NSObject {
    
    static var appVersionDescriptor : String {
        let bundle = Bundle.main
        let components = [bundle.oex_appName(), bundle.bundleIdentifier, bundle.oex_buildVersionString()].compactMap{ return $0 }
        return components.joined(separator: "/")
    }
    
    static func webViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = appVersionDescriptor
        return config
    }
}

protocol WebViewConfigurationProvider {
    func webViewConfiguration() -> WKWebViewConfiguration
}

extension OEXConfig: WebViewConfigurationProvider {
    func webViewConfiguration() -> WKWebViewConfiguration {
        return UserAgentGenerator.webViewConfiguration()
    }
}
