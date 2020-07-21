//
//  RegistrationFormAPI.swift
//  edX
//
//  Created by Danial Zahid on 9/21/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct RegistrationFormAPI {
    private static let RegistrationValidationURL = "/api/user/v1/validation/registration"
    
    private static func registrationFormDeserializer(response : HTTPURLResponse, json : JSON) -> Result<OEXRegistrationDescription> {
        return json.dictionaryObject.map { OEXRegistrationDescription(dictionary: $0) }.toResult()
    }
    
    public static func registrationFormRequest(version: String) -> NetworkRequest<(OEXRegistrationDescription)> {
        let path = NSString.oex_string(withFormat: SIGN_UP_URL, parameters: ["version" : version])
        
        return NetworkRequest(method: .GET,
                              path: path,
                              deserializer: .jsonResponse(registrationFormDeserializer))
        
    }
    
    private static func regirationFromValidationDeserializer(response: HTTPURLResponse, json: JSON) -> Result<RegistrationFormValidation> {
        return RegistrationFormValidation(json: json).toResult()
    }
    
    public static func registrationFormValidationRequest(parameters: [String : String]) -> NetworkRequest<RegistrationFormValidation> {
        return NetworkRequest(method: .POST,
                              path: RegistrationValidationURL,
                              body: .jsonBody(JSON(parameters)),
                              deserializer: .jsonResponse(regirationFromValidationDeserializer))
    }
}
