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
    @objc public func URLCredentialForHost(_ host : NSString) -> URLCredential? {
        for item in self.basicAuthCredentials {
            if item.host.host ?? "" == host as String {
                return item.credential
            }
        }
        return nil
    }
}
