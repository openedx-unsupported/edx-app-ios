//
//  LogoutApi.swift
//  edX
//
//  Created by Saeed Bashir on 8/11/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

public struct LogoutApi {
    
    private static func invalidateTokenDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure()
        }
        
        return Success(v: ())
    }
    
    public static func invalidateToken(refreshToken: String, clientID: String) -> NetworkRequest<()> {
        let body = ["token": refreshToken, "client_id": clientID, "token_type_hint": "refresh_token"]
        return NetworkRequest(
            method: .POST,
            path: "/oauth2/revoke_token/",
            body: RequestBody.formEncoded(body),
            deserializer: .noContent(invalidateTokenDeserializer)
        )
    }
}
