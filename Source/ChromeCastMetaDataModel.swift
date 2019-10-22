//
//  ChromeCastMetaDataModel.swift
//  edX
//
//  Created by Muhammad Umer on 10/29/19.
//  Copyright © 2019 edX. All rights reserved.
//

import Foundation
import GoogleCast

/// Extension of GCKMediaInformation to allow building of media information with meta data to be provided to chrome cast Device
extension GCKMediaInformation {
    static func buildMediaInformation(contentID: String, title: String, contentType: ChromeCastContentType, streamType: GCKMediaStreamType, thumbnailUrl: String?, deviceName: String?) -> GCKMediaInformation {
        let metadata = GCKMediaMetadata(metadataType: .movie)
        metadata.setString(title, forKey: kGCKMetadataKeyTitle)
        metadata.setString(deviceName ?? "", forKey: kGCKMetadataKeyStudio)

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
