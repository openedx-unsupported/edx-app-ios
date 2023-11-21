//
//  ChromeCastMetaDataModel.swift
//  edX
//
//  Created by Muhammad Umer on 10/29/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

let ChromeCastVideoID = "ChromeCastVideoID"
let ChromeCastCourseID = "ChromeCastCourseID"

/// Extension of GCKMediaInformation to allow building of media information with meta data to be provided to chrome cast Device
extension GCKMediaInformation {
    static func buildMediaInformation(courseID: String, contentID: String, title: String, videoID: String, contentType: ChromeCastContentType, streamType: GCKMediaStreamType, thumbnailUrl: String?, deviceName: String?) -> GCKMediaInformation {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(title, forKey: kGCKMetadataKeyTitle)
        metadata.setString(deviceName ?? "", forKey: kGCKMetadataKeyStudio)
        metadata.setString(courseID, forKey: ChromeCastCourseID)
        metadata.setString(videoID, forKey: ChromeCastVideoID)

        if let thumbnailUrl = thumbnailUrl, let url = URL(string: thumbnailUrl) {
            metadata.addImage(GCKImage(url: url, width: Int(UIScreen.main.bounds.width), height: Int(UIScreen.main.bounds.height)))
        }

        let mediaInformationBuilder = GCKMediaInformationBuilder()
        mediaInformationBuilder.contentID = contentID
        mediaInformationBuilder.streamType = streamType
        mediaInformationBuilder.contentType = contentType.rawValue
        mediaInformationBuilder.metadata = metadata

        return mediaInformationBuilder.build()
    }
}
