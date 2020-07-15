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
    
    private enum Keys: String {
        case validationDecisions = "validation_decisions"
    }
    
    public init?(json: JSON) {
        let validationDecisionJson = json[Keys.validationDecisions.rawValue]
        validationDecisions = ValidationDecisions(json: validationDecisionJson) ?? nil
    }
}

class ValidationDecisions: NSObject {
    @objc let name, email, username, password, country: String
    
    private enum Keys: String {
        case name
        case email
        case username
        case password
        case country
    }
    
    public init?(json: JSON) {
        name = json[Keys.name.rawValue].string ?? ""
        email = json[Keys.email.rawValue].string ?? ""
        username = json[Keys.username.rawValue].string ?? ""
        password = json[Keys.password.rawValue].string ?? ""
        country = json[Keys.country.rawValue].string ?? ""
    }
}
