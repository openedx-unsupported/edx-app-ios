//
//  MicrosoftSocial.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

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
    
    private let kCurrentAccountIdentifier = "MSALCurrentAccountIdentifier"
    private let kGraphURI = "https://graph.microsoft.com/v1.0/me/" // the Microsoft Graph endpoint
    private var accessToken = String()
    private var webViewParameters : MSALWebviewParameters?
    private var completionHandler: MSLoginCompletionHandler?
    private var applicationContext = MSALPublicClientApplication()
    var result: MSALResult?
    
    private let kAuthority = "https://login.microsoftonline.com/common/v2.0"
    private let kScopes = ["User.Read"]
    
    var currentAccountIdentifier: String? {
        get {
            return UserDefaults.standard.string(forKey: kCurrentAccountIdentifier)
        }
        set (accountIdentifier) {
            UserDefaults.standard.set(accountIdentifier, forKey: kCurrentAccountIdentifier)
        }
    }
    
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
                
                guard let acquireTokenResult = result, error == nil else {
                    completion(nil, nil, error)
                    return
                }
                
                // In the initial acquire token call we'll want to look at the account object
                // that comes back in the result.
                let signedInAccount = acquireTokenResult.account
                self.currentAccountIdentifier = signedInAccount.homeAccountId?.identifier
                
                completion(signedInAccount, acquireTokenResult.accessToken, nil)
            }
        } catch let createApplicationError {
            completion(nil, nil, createApplicationError)
        }
    }
    
    func createClientApplication() throws -> MSALPublicClientApplication {
        // Initialize a MSALPublicClientApplication with a given clientID and authority
        guard let kClientID = OEXConfig.shared().microsoftConfig.appID else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }
        // This MSALPublicClientApplication object is the representation of your app listing, in MSAL. For your own app
        // go to the Microsoft App Portal to register your own applications with their own client IDs.
        let config = MSALPublicClientApplicationConfig(clientId: kClientID)
        do {
            return try MSALPublicClientApplication(configuration: config)
        } catch _ as NSError {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.publicClientApplicationCreation.rawValue, userInfo: nil)
        }
    }
    
    @discardableResult func currentAccount() throws -> MSALAccount {
        // We retrieve our current account by checking for the accountIdentifier that we stored in NSUserDefaults when
        // we first signed in the account.
        guard let accountIdentifier = currentAccountIdentifier else {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.noUserSignedIn.rawValue, userInfo: nil)
        }
        
        let clientApplication = try createClientApplication()
        
        var account: MSALAccount?
        do {
            account = try clientApplication.account(forIdentifier: accountIdentifier)
        } catch _ as NSError {
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.userNotFound.rawValue, userInfo: nil)
        }
        
        guard let currentAccount = account else {
            clearCurrentAccount()
            throw NSError(domain: "MSALErrorDomain", code: MSALError.custom.noUserSignedIn.rawValue, userInfo: nil)
        }
        
        return currentAccount
    }
    
    func clearCurrentAccount() {
        // Leave around the account identifier as the last piece of state to clean up as you will probably need
        // it to clean up user-specific state
        UserDefaults.standard.removeObject(forKey: kCurrentAccountIdentifier)
    }
    
    func requestUserProfileInfo(completion: (_ user: MSALAccount) -> Void) {
        guard let user = result?.account else {
            return
        }
        completion(user)
    }
    
    private func logout() {
        do {
            let accountToDelete = try? currentAccount()
            
            // Signing out an account requires removing this from MSAL and cleaning up any extra state that the application
            // might be maintaining outside of MSAL for the account.
            
            // This remove call only removes the account's tokens for this client ID in the local keychain cache. It does
            // not sign the account completely out of the device or remove tokens for the account for other client IDs. If
            // you have multiple applications sharing a client ID this will make the account effectively "disappear" for
            // those applications as well if you are using Keychain Cache Sharing (not currently available in MSAL
            // build preview). We do not recommend sharing a ClientID among multiple apps.
            
            if let accountToDelete = accountToDelete {
                let application = try createClientApplication()
                try application.remove(accountToDelete)
            }
            clearCurrentAccount()
        } catch let error {
            Logger.logError("Logout","Received error signing user out:: \(error)")
        }
    }
}
