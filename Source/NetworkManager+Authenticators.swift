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
    public func addAuthenticator(router:OEXRouter, session:OEXSession, clientId:String) {
        let invalidAccessInterceptor = {[weak router] response, data in
            NetworkManager.invalidAccessAuthenticator(router, session: session, clientId:clientId, response: response, data: data)
        }
        addAuthenticator(invalidAccessInterceptor)
    }
    
    // 
    static func invalidAccessAuthenticator(router: OEXRouter?, session:OEXSession, clientId:String, response: NSHTTPURLResponse?, data: NSData?) -> AuthenticationAction {
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
                dispatch_async(dispatch_get_main_queue()) {
                    router?.logout()
                }
                return AuthenticationAction.Proceed
            }
            
            if error.isAPIError(.OAuth2Expired) {
                return AuthenticationAction.Authenticate({ (networkManager, completion) in
                    let networkRequest = LoginAPI.refreshAccessToken(
                        refreshToken,
                        clientId: clientId,
                        grantType: "refresh_token"
                    )
                    networkManager.taskForRequest(networkRequest) {result in
                        if let newAccessToken = result.data {
                            session.saveAccessToken(newAccessToken, userDetails: session.currentUser!)
                            completion(success: true)
                        } else {
                            completion(success: false)
                        }
                    }
                })
            } else if error.isAPIError(.OAuth2Nonexistent) {
                dispatch_async(dispatch_get_main_queue()) {
                    router?.logout()
                }
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            router?.logout()
        }
        return AuthenticationAction.Proceed
    }
}
