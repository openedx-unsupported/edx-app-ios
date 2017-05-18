//
//  RegistrationFormAPI.swift
//  edX
//
//  Created by Danial Zahid on 9/21/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct RegistrationFormAPI {
    
    static func registrationFormDeserializer(response : HTTPURLResponse, json : JSON) -> Result<OEXRegistrationDescription> {
        return json.dictionaryObject.map { OEXRegistrationDescription(dictionary: $0) }.toResult()
    }
    
    public static func registrationFormRequest() -> NetworkRequest<(OEXRegistrationDescription)> {
        return NetworkRequest(method: .GET,
                              path: SIGN_UP_URL,
                              deserializer: .jsonResponse(registrationFormDeserializer))
        
    }
}
