//
//  NetworkManager+Authenticators.swift
//  edX
//
//  Created by Christopher Lee on 5/13/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

import edXCore

extension NetworkManager {
    
    public func addRefreshTokenAuthenticator(router:OEXRouter, session:OEXSession, clientId:String) {
        let invalidAccessAuthenticator = {[weak router] response, data in
            NetworkManager.invalidAccessAuthenticator(router, session: session, clientId:clientId, response: response, data: data)
        }
        self.authenticator = invalidAccessAuthenticator
    }
    
    /** Checks if the response's status code is 401. Then checks the error
     message for an expired access token. If so, a new network request to
     refresh the access token is made and this new access token is saved.
     */
    public static func invalidAccessAuthenticator(router: OEXRouter?, session:OEXSession, clientId:String, response: NSHTTPURLResponse?, data: NSData?) -> AuthenticationAction {
        if let data = data,
            response = response,
            raw : AnyObject = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
        {
            let json = JSON(raw)
            
            guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
                error = NSError(json: json, code: response.statusCode)
                where statusCode == .Code401Unauthorised else
            {
                return AuthenticationAction.Proceed
            }
            
            guard let refreshToken = session.token?.refreshToken else {
                return logout(router)
            }
            
            if error.isAPIError(.OAuth2Expired) {
                return refreshAccessToken(clientId, refreshToken: refreshToken, session: session)
            }
            
            // This case should not happen on production. It is useful for devs
            // when switching between development environments.
            if error.isAPIError(.OAuth2Nonexistent) {
                return logout(router)
            }
        }
        Logger.logError("Network Authenticator", "Request failed: " + response.debugDescription)
        return AuthenticationAction.Proceed
    }
}

private func logout(router:OEXRouter?) -> AuthenticationAction {
    dispatch_async(dispatch_get_main_queue()) {
        router?.logout()
    }
    return AuthenticationAction.Proceed
}

/** Creates a networkRequest to refresh the access_token. If successful, the
 new access token is saved and a successful AuthenticationAction is returned.
 */
private func refreshAccessToken(clientId:String, refreshToken:String, session: OEXSession) -> AuthenticationAction {
    return AuthenticationAction.Authenticate({ (networkManager, completion) in
        let networkRequest = LoginAPI.requestTokenWithRefreshToken(
            refreshToken,
            clientId: clientId,
            grantType: "refresh_token"
        )
        networkManager.taskForRequest(networkRequest) {result in
            guard let currentUser = session.currentUser, let newAccessToken = result.data else {
                return completion(success: false)
            }
            session.saveAccessToken(newAccessToken, userDetails: currentUser)
            return completion(success: true)
        }
    })
}