//
//  BannerAPI.swift
//  edX
//
//  Created by Saeed Bashir on 9/29/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

public struct BannerAPI {

    private static func unacknowledgeddeserializer(response: HTTPURLResponse, json: JSON) -> Result<[String]> {
        guard let statusCode = OEXHTTPStatusCode(rawValue: response.statusCode), !statusCode.is2xx else {
            let values = json["results"].arrayValue.map { $0.stringValue }
            return Success(v: values)
        }
        return Failure()
    }

    static func unacknowledgedAPI() -> NetworkRequest<[String]> {
        return NetworkRequest<[String]>(
            method: .GET,
            path: "/notices/api/v1/unacknowledged?mobile=true",
            requiresAuth: true,
            deserializer: .jsonResponse(unacknowledgeddeserializer))
    }
}
