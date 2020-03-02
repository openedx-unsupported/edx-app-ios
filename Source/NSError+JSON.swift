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
    case Code = "error_code"
    case DeveloperMessage = "developer_message"
}

extension NSError {
    convenience init?(json: JSON, code: Int) {
        guard let info = json.object as? [NSObject : AnyObject] else {
            return nil
        }
        self.init(domain: OEXErrorDomain, code: code, userInfo: info as? [String : Any])
    }

    func isAPIError(code: APIErrorCode) -> Bool {
        guard let errorCode = errorInfo?[ErrorFields.Code.rawValue] as? String else { return false }
        return errorCode == code.rawValue
    }
    
    /// error_code can be in the different hierarchy. Like it can be direct or it can be contained in a dictionary under developer_message
    private var errorInfo: Dictionary<AnyHashable, Any>? {
        guard let errorInfo = userInfo[ErrorFields.DeveloperMessage.rawValue] as? Dictionary<AnyHashable, Any>  else {
            return userInfo
        }
        
        return errorInfo
    }
}
