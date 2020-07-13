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
    
    public init?(json: JSON) {
        let validationDecisionJson = json["validation_decisions"]
        validationDecisions = ValidationDecisions(json: validationDecisionJson) ?? nil
    }
}

class ValidationDecisions: NSObject {
    @objc let name, email, username, password, country: String
    
    public init?(json: JSON) {
        name = json["name"].string ?? ""
        email = json["email"].string ?? ""
        username = json["username"].string ?? ""
        password = json["password"].string ?? ""
        country = json["country"].string ?? ""
    }
}
