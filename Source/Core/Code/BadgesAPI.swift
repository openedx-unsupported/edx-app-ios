//
//  BadgesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//


public struct BadgesAPI {

    private static func badgeAssertionsDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<[BadgeAssertion]> {
        return (json.array?.mapSkippingNils { BadgeAssertion(json: $0) }).toResult(NetworkManager.unknownError)
    }

    public static func requestBadgesForUser(username : String) -> NetworkRequest<[BadgeAssertion]> {
        return NetworkRequest(
            method: .GET,
            path: "api/badges/v1/assertions/user/{username}".oex_formatWithParameters(["username": username]),
            deserializer: .JSONResponse(badgeAssertionsDeserializer)
        )
    }

}
