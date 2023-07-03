//
//  MicrosoftSocial.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import MSAL

typealias MSLoginCompletionHandler = (MSALAccount?, String?, Error?) -> Void

extension MSALError {
    enum Custom: Int {
        case publicClientApplicationCreation = -500010
        case noUserSignedIn = -500011
        case userNotFound = -500012
    }
}

final class MicrosoftSocial: NSObject {

    static let shared = MicrosoftSocial()

    private let scopes = ["User.Read", "email"]
    private var result: MSALResult?

    private override init() {
        super.init()
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, observer, _) in
            observer.logout()
        }
    }

    func loginFromController(controller: UIViewController, completion: @escaping MSLoginCompletionHandler) {
        do {
            let clientApplication = try createClientApplication()

            let webParameters = MSALWebviewParameters(authPresentationViewController: controller)
            let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webParameters)
            clientApplication.acquireToken(with: parameters) { [weak self] (result: MSALResult?, error: Error?) in
                guard let self = self else { return }

                guard let result = result, error == nil else {
                    completion(nil, nil, error)
                    return
                }

                self.result = result
                let account = result.account
                completion(account, result.accessToken, nil)
            }
        } catch let createApplicationError {
            completion(nil, nil, createApplicationError)
        }
    }

    private func createClientApplication() throws -> MSALPublicClientApplication {
        guard let clientID = OEXConfig.shared().microsoftConfig.appID else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.Custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }

        let configuration = MSALPublicClientApplicationConfig(clientId: clientID)

        do {
            return try MSALPublicClientApplication(configuration: configuration)
        } catch {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.Custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }
    }

    @discardableResult
    private func currentAccount() throws -> MSALAccount {
        let clientApplication = try createClientApplication()

        guard let account = try clientApplication.allAccounts().first else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.Custom.userNotFound.rawValue, userInfo: nil)
        }

        return account
    }

    func getUser(completion: (MSALAccount) -> Void) {
        guard let user = result?.account else { return }
        completion(user)
    }

    private func logout() {
        do {
            let account = try? currentAccount()

            if let account = account {
                let application = try createClientApplication()
                try application.remove(account)
            }
        } catch let error {
            Logger.logError("Logout", "Received error signing user out: \(error)")
        }
    }
}
