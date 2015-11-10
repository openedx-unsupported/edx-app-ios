//
//  BasicAuthCredentialManager.swift
//  edX
//
//  Created by Akiva Leffert on 11/6/15.
//  Copyright © 2015 edX. All rights reserved.
//

import WebKit
import UIKit

extension OEXConfig : URLCredentialProvider {
    @objc public func URLCredentialForHost(host : NSString) -> NSURLCredential? {
        for item in self.basicAuthCredentials() {
            if item.host.host == host {
                return item.URLCredential
            }
        }
        return nil
    }
}
