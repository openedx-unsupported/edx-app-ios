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
    
    /** If needsTokenRefresh is true, then a network request to refresh the access
     token is made. Otherwise Checks if the response's status code is 401. Then
     checks the error message for an expired access token. If so, a new network
     request to refresh the access token is made and this new access token is saved.
     */
    public static func invalidAccessAuthenticator(router: OEXRouter?, session: OEXSession, clientId: String, response: HTTPURLResponse?, data: Data?, needsTokenRefresh: Bool) -> AuthenticationAction {
        // If access token is expired, then we must call the refresh access token API call.
        if needsTokenRefresh {
            guard let refreshToken = session.token?.refreshToken else {
                return logout(router: router)
            }
            return refreshAccessToken(router: router, clientId: clientId, refreshToken: refreshToken, session: session)
        }
        
        if let data = data,
           let response = response {
            do {
                let raw = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                let json = JSON(raw)
                
                guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode),
                      let error = NSError(json: json, code: response.statusCode), statusCode.is4xx
                else { return .proceed }
                
                guard let token = session.token, let refreshToken = token.refreshToken else {
                    return logout(router: router)
                }
                
                if let error = error.apiError {
                    switch error.action {
                    case .doNothing:
                        Logger.logError("Network Authenticator", "\(error.rawValue): " + response.debugDescription)
                    case .refresh:
                        if router?.environment.networkManager.tokenStatus == .valid {
                        return refreshAccessToken(router: router, clientId: clientId, refreshToken: refreshToken, session: session)
                    } else {
                        return .queue
                    }
                    case .logout:
                        return logout(router: router)
                    }
                }
            } catch let error {
                print("Failed to load: \(error.localizedDescription)")
            }
        }
        
        Logger.logError("Network Authenticator", "Request failed: " + response.debugDescription)
        return .proceed
    }
}

private func logout(router: OEXRouter?) -> AuthenticationAction {
    router?.environment.networkManager.removeAllQueuedTasks()
    DispatchQueue.main.async {
        router?.logout()
    }
    return .proceed
}

/** Creates a networkRequest to refresh the access_token. If successful, the
 new access token is saved and a successful AuthenticationAction is returned.
 */
private func refreshAccessToken(router: OEXRouter?, clientId: String, refreshToken: String, session: OEXSession) -> AuthenticationAction {
    logTestAnalayticsForCrash(router: router, name: "TestEvent: Refreshing Token")
    router?.environment.networkManager.tokenStatus = .authenticating
    
    return .authenticate { networkManager, completion in
        let networkRequest = LoginAPI.requestTokenWithRefreshToken(refreshToken: refreshToken, clientId: clientId)
        
        networkManager.performTaskForRequest(networkRequest) { [weak networkManager] result in
            var success = false
            if let currentUser = session.currentUser {
                if let newAccessToken = result.data {
                    success = true
                    session.save(newAccessToken, userDetails: currentUser)
                    networkManager?.tokenStatus = .valid
                } else {
                    networkManager?.tokenStatus = .expired
                }
            }
            performQueuedTasks(router: router, success: success)
            
            return completion(success)
        }
    }
}

private func performQueuedTasks(router: OEXRouter?, success: Bool) {
    DispatchQueue.main.async {
        if success == true {
            router?.environment.networkManager.performQueuedTasks(success: success)
        }
        else {
            router?.environment.networkManager.removeAllQueuedTasks()
        }
        logTestAnalayticsForCrash(router: router, name: "TestEvent: Token Refreshed \(success)")
    }
}

private func logTestAnalayticsForCrash(router: OEXRouter?, name: String) {
    #if DEBUG
    return
    #endif
    
    let event = OEXAnalyticsEvent()
    event.displayName = name;
    let info = [
        "token_status": router?.environment.networkManager.tokenStatus.rawValue ?? 100
    ] as [String : Any]

    router?.environment.analytics.trackEvent(event, forComponent: nil, withInfo: info)
}
