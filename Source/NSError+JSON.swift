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
        guard let errorInfo = parseError(info: userInfo) else { return false }
        let errorCode = errorInfo[ErrorFields.errorCode.rawValue] as? String
        return errorCode == code.rawValue
    }

    /// error_code can be in the different hierarchy. Like it can be direct or it can be contained in a dictionary under developer_message
    private func parseError(info: Dictionary<AnyHashable, Any>?) -> Dictionary<AnyHashable, Any>? {
        var errorVaule: Any?

        if (info?[ErrorFields.errorCode.rawValue] != nil) {
            errorVaule = info?[ErrorFields.errorCode.rawValue]
        }
        else if (info?[ErrorFields.error.rawValue] != nil) {
            errorVaule = info?[ErrorFields.error.rawValue]
        }
        else if (info?[ErrorFields.developerMessage.rawValue] != nil) {
            errorVaule = info?[ErrorFields.developerMessage.rawValue]
            if let infoDict = errorVaule as? Dictionary<AnyHashable, Any> {
                return parseError(info: infoDict)
            }
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
