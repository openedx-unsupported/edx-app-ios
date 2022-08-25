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
    
    @objc public func addRefreshTokenAuthenticator(router: OEXRouter, session: OEXSession, clientId: String) {
        let invalidAccessAuthenticator = { [weak router] response, data, needsTokenRefresh in
            NetworkManager.invalidAccessAuthenticator(router: router, session: session, clientId:clientId, response: response, data: data, needsTokenRefresh: needsTokenRefresh)
        }
        self.authenticator = invalidAccessAuthenticator
        
    }
    
    /** Checks if the response's status code is 401. Then checks the error
     message for an expired access token. If so, a new network request to
     refresh the access token is made and this new access token is saved.
     */
    public static func invalidAccessAuthenticator(router: OEXRouter?, session: OEXSession, clientId: String, response: HTTPURLResponse?, data: Data?, needsTokenRefresh: Bool) -> AuthenticationAction {
        
        // If access token is expired, then we must call the refresh access token API call.
        if needsTokenRefresh {
            return refreshAccessToken(router: router, clientId: clientId, refreshToken: session.token?.refreshToken ?? "", session: session)
        }
        
        if let data = data,
            let response = response
        {
            do {
                let raw = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions())
                let json = JSON(raw)
                
                guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
                    let error = NSError(json: json, code: response.statusCode), statusCode.is4xx else
                {
                    return .proceed
                }
                
                guard let refreshToken = session.token?.refreshToken else {
                    return logout(router: router)
                }
                
                // Retry request with the current access_token if the original access_token used in
                // request does not match the current access_token. This case can occur when
                // asynchronous calls are made and are attempting to refresh the access_token where
                // one call succeeds but the other fails.
                
                if error.isAPIError(code: .OAuth2Expired) || error.isAPIError(code: .OAuth2Nonexistent) {
                    if router?.environment.networkManager.tokenStatus == .valid {
                        return refreshAccessToken(router: router, clientId: clientId, refreshToken: refreshToken, session: session)
                    } else {
                        return .queue
                    }
                }
                
                if error.isAPIError(code: .OAuth2InvalidGrant) || error.isAPIError(code: .OAuth2DisabledUser) {
                    return logout(router: router)
                }
            }
            catch  let error as NSError {
                print("Failed to load: \(error.localizedDescription)")
            }
            
        }
        
        Logger.logError("Network Authenticator", "Request failed: " + response.debugDescription)
        return .proceed
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
private func refreshAccessToken(router: OEXRouter?, clientId: String, refreshToken: String, session: OEXSession) -> AuthenticationAction {
    
    // Set token status refreshing
    router?.environment.networkManager.tokenStatus = .authenticating
    
    return AuthenticationAction.authenticate( { (networkManager,  completion) in
        
        let networkRequest = LoginAPI.requestTokenWithRefreshToken(
            refreshToken: refreshToken,
            clientId: clientId,
            grantType: "refresh_token"
        )
        
        networkManager.performTaskForRequest(networkRequest) { [weak networkManager] result in
            
            var success = false
            if let currentUser = session.currentUser {
                if let newAccessToken = result.data {
                    session.save(newAccessToken, userDetails: currentUser)
                    success = true
                    networkManager?.tokenStatus = .valid
                } else {
                    networkManager?.tokenStatus = .failedAuthentication
                }
                
                // We need to call this method to allow tasks to callback thier handlers with success or error
                networkManager?.performQueuedTasksIfAny(success: success, request: result.request, response: result.response, baseData: result.baseData, error: result.error)
            } else {
                // Remove all queued tasks if user details are not available in session
                networkManager?.removeAllQueuedTasks()
            }
            
            return completion(success)
        }
    })
}
