//
//  SessionUsernameProvider.swift
//  edX
//
//  Created by Akiva Leffert on 3/9/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

@objc public class SessionUsernameProvider : NSObject, PathProvider {
    private let session : OEXSession
    public init(session : OEXSession) {
        self.session = session
    }

    private var currentUsername : String? {
        return self.session.currentUser?.username
    }

    public func pathForRequestKey(key: String?) -> NSURL? {
        return OEXFileUtility.filePathForRequestKey(key, username: self.currentUsername).flatMap {NSURL(fileURLWithPath: $0)}
    }
}