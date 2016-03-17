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

    private static let shared = TestCredentialManager()

    private let config = OEXConfig(bundle: NSBundle(forClass: TestCredentialManager.self))

    private func freshCredentials() -> Credentials {
        let password = NSUUID().UUIDString
        let email = config.endToEndConfig.emailTemplate.oex_formatWithParameters(["unique_id": NSUUID().asUsername])
        let username = email.componentsSeparatedByString("@").first!
        return Credentials(username : username, password: password, email: email)
    }

    private lazy var defaultCredentials: Credentials = {
        let credentials = self.freshCredentials()
        self.registerUser(credentials)
        return credentials
    }()

    func registerUser(credentials: Credentials) {
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
    private let credentials : Credentials

    enum Type {
        case Fresh // Credentials without an existing account
        case Default // Standard test credentials. Have an account and registered for at least one course
    }

    init(type: Type = .Default) {
        switch type {
        case .Fresh:
            credentials = TestCredentialManager.shared.freshCredentials()
        case .Default:
            credentials = TestCredentialManager.shared.defaultCredentials
        }
    }

    var username: String { return credentials.username }
    var password: String { return credentials.password }
    var email: String { return credentials.email }
}
