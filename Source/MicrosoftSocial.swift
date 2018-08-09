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

    //Singleton
    static let shared = MicrosoftSocial()
    private var completionHandler: MSLoginCompletionHandler?
    private var applicationContext: MSALPublicClientApplication = MSALPublicClientApplication.init()
    var accessToken = ""
    
    //TODO: move in config
    let kClientID = "bdec02cb-c8a0-40b9-a964-a816f42fd070"
    let kAuthority = "https://login.microsoftonline.com/common/v2.0"
    let kScopes: [String] = ["https://graph.microsoft.com/user.read"]
    

    private override init() {
//        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXSessionEnded.rawValue, action: { (_, observer, _) in
//                //observer?.logout()
//            })
    }
    
    func loginFromController(controller: UIViewController, completionHandler: @escaping MSLoginCompletionHandler) {
        self.completionHandler = completionHandler
        
        setUpApplicationContext()
        
        do {
            // We check to see if we have a current signed-in user. If we don't, then we need to sign someone in.
            // We throw an interactionRequired so that we trigger the interactive sign-in.
            
            if  try applicationContext.users().isEmpty {
                throw NSError.init(domain: "MSALErrorDomain", code: MSALErrorCode.interactionRequired.rawValue, userInfo: nil)
            } else {
                // Acquire a token for an existing user silently
                //try application.acquireTokenSilent(forScopes: kScopes, user: applicationContext.users().first, authority: kAuthority) { [weak self] (result, error) in
                
                //}
            }
        } catch let error as NSError {
            // interactionRequired means we need to ask the user to sign in. This usually happens
            // when the user's Refresh Token is expired or if the user has changed their password
            // among other possible reasons.
            
            if error.code == MSALErrorCode.interactionRequired.rawValue {
                applicationContext.acquireToken(forScopes: self.kScopes) { [weak self] (result, error) in
                    self?.handleResponse(result: result, error: error)
                }
            }

        } catch {
            handleResponse(result: nil, error: error)
        }
        
    }
    
    private func handleResponse(result: MSALResult?, error: Error?) {
        if let result = result {
            accessToken = result.accessToken
            //send this token to server to get content after authentication
        } else {
            completionHandler(nil, error)
        }
    }
    
    private func setUpApplicationContext() {
        do {
            // Initialize a MSALPublicClientApplication with a given clientID and authority
            applicationContext = try MSALPublicClientApplication.init(clientId: kClientID, authority: kAuthority)
        } catch {
            // catch error
        }
    }
}
