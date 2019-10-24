//
//  VideoCompletionApi.swift
//  edX
//
//  Created by Saeed Bashir on 7/17/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

public struct VideoCompletionApi {

    private static func videoCompletionDeserializer(response : HTTPURLResponse) -> Result<()> {
        guard response.httpStatusCode.is2xx else {
            return Failure()
        }

        return Success(v: ())
    }

    public static func videoCompletion(username: String, courseID: String, blockID: String) -> NetworkRequest<()> {
        let body = RequestBody.jsonBody(JSON([
            "username": username,
            "course_key": courseID,
            "blocks" : [ blockID: 1.0]
            ]))

        return NetworkRequest(
            method: .POST,
            path: "/api/completion/v1/completion-batch",
            requiresAuth: true,
            body: body,
            deserializer: .noContent(videoCompletionDeserializer)
        )
    }
}
