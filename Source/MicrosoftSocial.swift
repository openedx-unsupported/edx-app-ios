//
//  MicrosoftSocial.swift
//  edX
//
//  Created by Salman on 07/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import MSAL

typealias MSLoginCompletionHandler = (_ accessToken: String?, _ error: Error?) -> Void

class MicrosoftSocial: NSObject {

    static let shared = MicrosoftSocial()
    private var completionHandler: MSLoginCompletionHandler?
    private var applicationContext = MSALPublicClientApplication()
    var result: MSALResult?
    
    private let kAuthority = "https://login.microsoftonline.com/common/v2.0"
    private let kScopes: [String] = ["https://graph.microsoft.com/user.read"]

    private override init() {
        super.init()
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue) { (_, Observer, _) in
            Observer.logout()
        }
    }
    
    func loginFromController(controller: UIViewController, completionHandler: @escaping MSLoginCompletionHandler) {
        self.completionHandler = completionHandler
        setUpApplicationContext()
        do {
            // We check to see if we have a current signed-in user. If we don't, then we need to sign someone in.
            // We throw an interactionRequired so that we trigger the interactive sign-in.
            
            if try applicationContext.users().isEmpty {
                throw NSError(domain: "MSALErrorDomain", code: MSALErrorCode.interactionRequired.rawValue, userInfo: nil)
            } else {
                // Acquire a token for an existing user silently.
                // If the error comes and says interaction required then we call interative sign-in.
                try applicationContext.acquireTokenSilent(forScopes: kScopes, user: applicationContext.users().first, authority: kAuthority) { [weak self] (result, error) in
                    
                    if let error  = error as NSError?, error.code == MSALErrorCode.interactionRequired.rawValue {
                        self?.acquireTokenInteractively()
                    }
                    else {
                        self?.handleResponse(result: result, error: error)
                    }
                }

            }
        } catch let error as NSError {
            if error.code == MSALErrorCode.interactionRequired.rawValue {
                acquireTokenInteractively()
            }

        } catch {
            handleResponse(result: nil, error: error)
        }
    }

    private func acquireTokenInteractively() {
        applicationContext.acquireToken(forScopes: kScopes) { [weak self] (result, error) in
            self?.handleResponse(result: result, error: error)
        }
    }
    
    private func handleResponse(result: MSALResult?, error: Error?) {
        guard let result = result else {
            completionHandler?(nil, error)
            return
        }
        
        self.result = result
        completionHandler?(result.accessToken, error)
    }
    
    private func setUpApplicationContext() {
        do {
            // Initialize a MSALPublicClientApplication with a given clientID and authority
            let clientID = OEXConfig.shared().microsoftConfig.appID
            applicationContext = try MSALPublicClientApplication(clientId: clientID, authority: kAuthority)
        } catch let error as NSError {
            completionHandler?(nil, error)
        }
    }
    
    func requestUserProfileInfo(completion: (_ user: MSALUser) -> Void) {
        guard let user = result?.user else {
            return
        }
        completion(user)
    }
    
    private func logout() {
        do {
            // Removes all tokens from the cache for this application for the provided user
            // first parameter:   The user to remove from the cache
            try applicationContext.remove(self.applicationContext.users().first)
            
        } catch let error {
            Logger.logError("Logout","Received error signing user out:: \(error)")
        }
    }
}
