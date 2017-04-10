//
//  TestCredentials.swift
//  edX
//
//  Created by Akiva Leffert on 3/14/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

private struct Credentials {
    let username : String
    let password: String
    let email: String
}

private class TestCredentialManager {

    fileprivate static let shared = TestCredentialManager()

    fileprivate let config = OEXConfig(bundle: Bundle(for: TestCredentialManager.self))

    fileprivate func freshCredentials() -> Credentials {
        let password = UUID().uuidString
        let email = config.endToEndConfig.emailTemplate.oex_format(withParameters: ["unique_id": UUID().asUsername])
        let username = email.components(separatedBy: "@").first!
        return Credentials(username : username, password: password, email: email)
    }

    fileprivate lazy var defaultCredentials: Credentials = {
        let credentials = self.freshCredentials()
        self.registerUser(credentials)
        return credentials
    }()

    func registerUser(_ credentials: Credentials) {
        let networkManager = NetworkManager(authorizationHeaderProvider: nil, credentialProvider: nil, baseURL: config.apiHostURL()!, cache: MockResponseCache())
        let body = [
            "email": credentials.email,
            "username": credentials.username,
            "password": credentials.password,
            "name": "Test Person",
            "honor_code": "true",
            "terms_of_service": "true"
        ]
        let registrationRequest = RegistrationAPI.registrationRequest(fields: body)
        let result = networkManager.streamForRequest(registrationRequest).waitForValue()
        assert(result.value != nil, "failed to register user")
    }
}

class TestCredentials {
    fileprivate let credentials : Credentials

    enum `Type` {
        case fresh // Credentials without an existing account
        case `default` // Standard test credentials. Have an account and registered for at least one course
    }

    init(type: Type = .default) {
        switch type {
        case .fresh:
            credentials = TestCredentialManager.shared.freshCredentials()
        case .default:
            credentials = TestCredentialManager.shared.defaultCredentials
        }
    }

    var username: String { return credentials.username }
    var password: String { return credentials.password }
    var email: String { return credentials.email }
}
