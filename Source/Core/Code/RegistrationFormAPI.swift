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
    
    public static func registrationFormRequest(version: String) -> NetworkRequest<(OEXRegistrationDescription)> {
        let path = NSString.oex_string(withFormat: SIGN_UP_URL, parameters: ["version" : version])
        
        return NetworkRequest(method: .GET,
                              path: path,
                              deserializer: .jsonResponse(registrationFormDeserializer))
        
    }
}
