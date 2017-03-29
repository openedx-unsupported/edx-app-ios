//
//  RegistrationAPI.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class RegistrationAPIError : NSError {

    struct Field {
        let userMessage: String
    }

    let fieldInfo : [String:Field]

    init(fields: [String:Field]) {
        self.fieldInfo = fields
        super.init(domain: "org.edx.mobile.registration", code: -1, userInfo: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public struct RegistrationAPI {
    
    static func registrationDeserializer(_ response : HTTPURLResponse, json: JSON) -> Result<()> {
        if response.httpStatusCode.is2xx {
            return .success(())
        }
        else if response.httpStatusCode == OEXHTTPStatusCode.code400BadRequest {
            var fields: [String:RegistrationAPIError.Field] = [:]
            for (key, value) in json.dictionaryValue {
                if let message = value.array?.first?["user_message"].string {
                    fields[key] = RegistrationAPIError.Field(userMessage: message)
                }
            }
            return .failure(RegistrationAPIError(fields: fields))
        }
        return .failure(NetworkManager.unknownError)
    }

    // Registers a new user
    public static func registrationRequest(fields: [String:String]) -> NetworkRequest<()> {
        return NetworkRequest(
            method: .POST,
            path: "/user_api/v1/account/registration/",
            body: .formEncoded(fields),
            deserializer: .jsonResponse(registrationDeserializer))
    }
    
}
