//
//  NSError+JSON.swift
//  edX
//
//  Created by Michael Katz on 1/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

enum APIErrorCodeAction {
    case doNothing
    case logout
    case refresh
}

enum APIErrorCode: String, CaseIterable {
    case OAuth2Expired = "token_expired"
    // Retry request with the current access_token if the original access_token used in
    // request does not match the current access_token. This case can occur when
    // asynchronous calls are made and are attempting to refresh the access_token where
    // one call succeeds but the other fails.
    case OAuth2Nonexistent = "token_nonexistent"
    //TODO: Handle invalid_grant gracefully,
    //Most of the times it's happening because of hitting /oauth2/access_token/ multiple times with refresh_token
    //Only send one request for /oauth2/access_token/
    case OAuth2InvalidGrant = "invalid_grant"
    case OAuth2DisabledUser = "user_is_disabled"
    
    case JWTTokenExpired = "Token has expired."
    case JWTerrorDecodingToken = "Error decoding token."
    case JWTInvalidToken = "Invalid token."
    case JWTTokenIsBlacklisted = "Token is blacklisted."
    case JWTMustIncludePreferredClaim = "JWT must include a preferred_username or username claim!"
    case JWTUserRetrievalFailed = "User retrieval failed."
    case JWTUserDisabled = "account_disabled"
    
    var action: APIErrorCodeAction {
        switch self {
        case .JWTTokenExpired, .OAuth2Expired:
            return .refresh
        default:
            return .logout
        }
    }
}

fileprivate enum ErrorFields: String, RawStringExtractable, CaseIterable {
    case errorCode = "error_code"
    case error = "error"
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
    
    var apiError: APIErrorCode? {
        guard let errorInfo = parseError(info: userInfo),
              let errorCode = errorInfo[ErrorFields.errorCode.rawValue] as? String,
              let error = APIErrorCode.allCases.first(where: { $0.rawValue == errorCode })
        else { return nil }
        return error
    }

    func isAPIError(of type: APIErrorCode) -> Bool {
        guard let errorInfo = parseError(info: userInfo) else { return false }
        let errorCode = errorInfo[ErrorFields.errorCode.rawValue] as? String
        return errorCode == type.rawValue
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
