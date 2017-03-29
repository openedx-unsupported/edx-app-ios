//
//  BadgesAPI.swift
//  edX
//
//  Created by Akiva Leffert on 3/31/16.
//  Copyright © 2016 edX. All rights reserved.
//


public struct BadgesAPI {

    fileprivate static func badgeAssertionsDeserializer(_ response : HTTPURLResponse, json : JSON) -> Result<[BadgeAssertion]> {
        return (json.array?.mapSkippingNils { BadgeAssertion(json: $0) }).toResult(NetworkManager.unknownError)
    }

    public static func requestBadgesForUser(_ username : String, page: Int = 1) -> NetworkRequest<Paginated<[BadgeAssertion]>> {
        return NetworkRequest(
            method: .GET,
            path: "api/badges/v1/assertions/user/{username}".oex_format(withParameters: ["username": username]),
            deserializer: .jsonResponse(badgeAssertionsDeserializer)
        ).paginated(page: page)
    }

}
