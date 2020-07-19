//
//  RegistrationFormValidation.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

public class RegistrationFormValidation: NSObject {
    let validationDecisions: ValidationDecisions?
    
    private enum Keys: String, RawStringExtractable {
        case validationDecisions = "validation_decisions"
    }
    
    public init?(json: JSON) {
        let validationDecisionJson = json[Keys.validationDecisions]
        validationDecisions = ValidationDecisions(json: validationDecisionJson) ?? nil
    }
}

class ValidationDecisions: NSObject {
    @objc let name, email, username, password, country: String
    
    enum Keys: String, RawStringExtractable {
        case name
        case email
        case username
        case password
        case country
    }
    
    public init?(json: JSON) {
        name = json[Keys.name].string ?? ""
        email = json[Keys.email].string ?? ""
        username = json[Keys.username].string ?? ""
        password = json[Keys.password].string ?? ""
        country = json[Keys.country].string ?? ""
    }
}
