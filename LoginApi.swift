//
//  LoginApi.swift
//  edX
//
//  Created by Christopher Lee on 5/13/16.
//  Copyright © 2016 edX. All rights reserved.
//

public struct LoginAPI {
    
    static func refreshTokenDeserializer(response : HTTPURLResponse, json: JSON) -> Result<OEXAccessToken> {
        guard response.httpStatusCode.is2xx,
            let dictionary = json.dictionaryObject else {
                return .failure(NetworkManager.unknownError)
        }
        let token = OEXAccessToken(tokenDetails: dictionary)
        return .success(token)
    }
    
    // Retrieves a new access token by using the refresh token.
    public static func requestTokenWithRefreshToken(refreshToken: String, clientId: String, grantType: String) -> NetworkRequest<OEXAccessToken> {
        let body = ["refresh_token": refreshToken, "client_id": clientId, "grant_type": grantType]
        return NetworkRequest(
            method: .POST,
            path: "/oauth2/access_token/",
            body: RequestBody.formEncoded(body),
            deserializer: .jsonResponse(refreshTokenDeserializer)
        )
    }
}
