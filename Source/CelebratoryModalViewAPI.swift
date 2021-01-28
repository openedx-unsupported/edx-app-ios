//
//  CelebratoryModalViewAPI.swift
//  edX
//
//  Created by Salman on 27/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

public struct CelebratoryModalViewAPI {

    private static func celebratoryModalViewDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure()
        }

        return Success(v: ())
    }

    public static func celebratoryModalViewed(courseID: String, isFirstSectionViewed: Bool) -> NetworkRequest<()> {
        let body = RequestBody.jsonBody(JSON([
            "first_section": isFirstSectionViewed,
            ]))

        return NetworkRequest(
            method: .POST,
            path: "/api/courseware/celebration/\(courseID)",
            requiresAuth: true,
            body: body,
            deserializer: .noContent(celebratoryModalViewDeserializer)
        )
    }
}
