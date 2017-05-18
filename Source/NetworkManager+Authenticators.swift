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
            NetworkManager.invalidAccessAuthenticator(router: router, session: session, clientId:clientId, response: response, data: data)
        }
        self.authenticator = invalidAccessAuthenticator
        
    }
    
    /** Checks if the response's status code is 401. Then checks the error
     message for an expired access token. If so, a new network request to
     refresh the access token is made and this new access token is saved.
     */
    public static func invalidAccessAuthenticator(router: OEXRouter?, session:OEXSession, clientId:String, response: HTTPURLResponse?, data: Data?) -> AuthenticationAction {
        if let data = data,
            let response = response
        {
            do {
                let raw = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions())
                let json = JSON(raw)
                
                guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
                    let error = NSError(json: json, code: response.statusCode), statusCode == .code401Unauthorised else
                {
                    return AuthenticationAction.proceed
                }
                
                guard let refreshToken = session.token?.refreshToken else {
                    return logout(router: router)
                }
                
                if error.isAPIError(code: .OAuth2Expired) {
                    return refreshAccessToken(clientId: clientId, refreshToken: refreshToken, session: session)
                }
                
                // This case should not happen on production. It is useful for devs
                // when switching between development environments.
                if error.isAPIError(code: .OAuth2Nonexistent) {
                    return logout(router: router)
                }
            }
            catch  let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
            
        }
        Logger.logError("Network Authenticator", "Request failed: " + response.debugDescription)
        return AuthenticationAction.proceed
    }
}

private func logout(router:OEXRouter?) -> AuthenticationAction {
    DispatchQueue.main.async {
        router?.logout()
    }
    return AuthenticationAction.proceed
}

/** Creates a networkRequest to refresh the access_token. If successful, the
 new access token is saved and a successful AuthenticationAction is returned.
 */
private func refreshAccessToken(clientId:String, refreshToken:String, session: OEXSession) -> AuthenticationAction {
    return AuthenticationAction.authenticate( { (networkManager,  completion) in
        let networkRequest = LoginAPI.requestTokenWithRefreshToken(
            refreshToken: refreshToken,
            clientId: clientId,
            grantType: "refresh_token"
        )
        networkManager.taskForRequest(networkRequest) {result in
            guard let currentUser = session.currentUser, let newAccessToken = result.data else {
                return completion(false)
            }
            session.save(newAccessToken, userDetails: currentUser)
            return completion(true)
        }
    })
}
