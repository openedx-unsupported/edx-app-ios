//
//  NSError+JSON.swift
//  edX
//
//  Created by Michael Katz on 1/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

import edXCore

enum APIErrorCode : String {
    case OAuth2Expired = "token_expired"
    case OAuth2Nonexistent = "token_nonexistent"
    case OAuth2InvalidGrant = "invalid_grant"
}

fileprivate enum ErrorFields: String, RawStringExtractable {
    case error = "error"
    case errorCode = "error_code"
    case developerMessage = "developer_message"
}

extension NSError {
    convenience init?(json: JSON, code: Int) {
        guard let info = json.object as? [NSObject : AnyObject] else {
            return nil
        }
        self.init(domain: OEXErrorDomain, code: code, userInfo: info as? [String : Any])
    }

    func isAPIError(code: APIErrorCode) -> Bool {
        guard let errorCode = errorInfo?[ErrorFields.errorCode.rawValue] as? String else { return false }
        return errorCode == code.rawValue
    }

    /// error_code can be in the different hierarchy. Like it can be direct or it can be contained in a dictionary under developer_message
    private var errorInfo: Dictionary<AnyHashable, Any>? {
        var errorVaule: Any?

        if (userInfo[ErrorFields.errorCode.rawValue] != nil) {
            errorVaule = userInfo[ErrorFields.errorCode.rawValue]
        }
        else if (userInfo[ErrorFields.error.rawValue] != nil) {
            errorVaule = userInfo[ErrorFields.error.rawValue]
        }
        else if (userInfo[ErrorFields.developerMessage.rawValue] != nil) {
            errorVaule = userInfo[ErrorFields.developerMessage.rawValue]
        }

        return errorInfo(value: errorVaule)
    }

    private func errorInfo(value: Any?) -> Dictionary<AnyHashable, Any>? {
        var errorInfo: Dictionary<AnyHashable, Any>? = [:]
        errorInfo?.setSafeObject(value, forKey: ErrorFields.errorCode.rawValue)

        if errorInfo?.count ?? 0 > 0 {
            return errorInfo
        }

        return userInfo
    }
}
