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

    // Registers a new user
    // -param parameters
    public static func registrationRequest(parameters: [String:String]) -> NetworkRequest<()> {
        return NetworkRequest(
            method: .POST,
            path: "/user_api/v1/account/registration/",
            body: .FormEncoded(parameters),
            deserializer: .JSONResponse({ (result, json) in
                print("result is \(result)\n json is \(json)")
                if result.httpStatusCode.is2xx {
                    return .Success(())
                }
                else if result.httpStatusCode == OEXHTTPStatusCode.Code400BadRequest {
                    var fields: [String:RegistrationAPIError.Field] = [:]
                    for (key, value) in json.dictionaryValue ?? [:] {
                        if let message = value.array?.first?["user_message"].string {
                            fields[key] = RegistrationAPIError.Field(userMessage: message)
                        }
                    }
                    return .Failure(RegistrationAPIError(fields: fields))
                }
                return .Failure(NetworkManager.unknownError)
            }))
    }
}