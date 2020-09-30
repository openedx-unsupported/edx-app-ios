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
    case OAuth2DisabledUser = "user_is_disabled"
}

fileprivate enum ErrorFields: String, RawStringExtractable {
    case error = "error"
    case errorCode = "error_code"
    case developerMessage = "developer_message"
    case detail = "detail"
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
        var errorValue: Any?

        if (info?[ErrorFields.errorCode.rawValue] != nil) {
            errorValue = info?[ErrorFields.errorCode.rawValue]
        }
        else if (info?[ErrorFields.error.rawValue] != nil) {
            errorValue = info?[ErrorFields.error.rawValue]
        }
        else if (info?[ErrorFields.developerMessage.rawValue] != nil) {
            errorValue = info?[ErrorFields.developerMessage.rawValue]
            if let infoDict = errorValue as? Dictionary<AnyHashable, Any> {
                return parseError(info: infoDict)
            }
        }
        else if (info?[ErrorFields.detail.rawValue] != nil) {
            errorValue = info?[ErrorFields.detail.rawValue]
        }

        return errorInfo(value: errorValue)
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
