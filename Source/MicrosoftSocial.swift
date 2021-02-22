//
//  MicrosoftSocial.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//
//
import UIKit
import MSAL

typealias MSLoginCompletionHandler =  (MSALAccount?, _ accessToken: String?, Error?) -> Void

extension MSALError {
    enum custom: Int {
        case publicClientApplicationCreation = -500010
        case noUserSignedIn = -500011
        case userNotFound = -500012
    }
}

class MicrosoftSocial: NSObject {

    static let shared = MicrosoftSocial()

    private let kScopes = ["User.Read", "email"]
    private var result: MSALResult?

    private override init() {
        super.init()
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, Observer, _) in
            Observer.logout()
        }
    }

    func loginFromController(controller : UIViewController, completion: @escaping MSLoginCompletionHandler) {
        do {
            let clientApplication = try createClientApplication()

            let webParameters = MSALWebviewParameters(parentViewController: controller)
            let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webParameters)
            clientApplication.acquireToken(with: parameters) {
                (result: MSALResult?, error: Error?) in

                guard let result = result, error == nil else {
                    completion(nil, nil, error)
                    return
                }
                self.result = result
                // In the initial acquire token call we'll want to look at the account object
                // that comes back in the result.
                let account = result.account

                completion(account, result.accessToken, nil)
            }
        } catch let createApplicationError {
            completion(nil, nil, createApplicationError)
        }
    }

    private func createClientApplication() throws -> MSALPublicClientApplication {
        // Initialize a MSALPublicClientApplication with a given clientID and authority
        guard let kClientID = OEXConfig.shared().microsoftConfig.appID else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }
        // This MSALPublicClientApplication object is the representation of your app listing, in MSAL. For your own app
        // go to the Microsoft App Portal to register your own applications with their own client IDs.
        let configuration = MSALPublicClientApplicationConfig(clientId: kClientID)
        do {
            return try MSALPublicClientApplication(configuration: configuration)
        } catch _ as NSError {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }
    }

    @discardableResult private func currentAccount() throws -> MSALAccount {
        let clientApplication = try createClientApplication()

        var account: MSALAccount?
        do {
            account = try clientApplication.allAccounts().first
        } catch _ as NSError {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.userNotFound.rawValue, userInfo: nil)
        }

        guard let currentAccount = account else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.noUserSignedIn.rawValue, userInfo: nil)
        }

        return currentAccount
    }

    func getUser(completion: (_ user: MSALAccount) -> Void) {
        guard let user = result?.account else {
            return
        }
        completion(user)
    }

    private func logout() {
        do {
            let account = try? currentAccount()

            // Signing out an account requires removing this from MSAL and cleaning up any extra state that the application
            // might be maintaining outside of MSAL for the account.

            // This remove call only removes the account's tokens for this client ID in the local keychain cache. It does
            // not sign the account completely out of the device or remove tokens for the account for other client IDs. If
            // you have multiple applications sharing a client ID this will make the account effectively "disappear" for
            // those applications as well if you are using Keychain Cache Sharing (not currently available in MSAL
            // build preview). We do not recommend sharing a ClientID among multiple apps.

            if let account = account {
                let application = try createClientApplication()
                try application.remove(account)
            }
        } catch let error {
            Logger.logError("Logout", "Received error signing user out:: \(error)")
        }
    }
}
