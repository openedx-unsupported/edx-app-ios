//
//  Errors.swift
//  YoutubeDirectLinkExtractor
//
//  Created by Andrey Sevrikov on 04/03/2018.
//  Copyright © 2018 Andrey Sevrikov. All rights reserved.
//

import Foundation

enum YoutubeLinkExtractorError: String, LocalizedError {
    case cantExtractVideoId = "Couldn't extract video id from the url"
    case cantConstructRequestUrl = "Couldn't construct URL for youtube info request"
    case noDataInResponse = "No data in youtube info response"
    case cantConvertDataToString = "Couldn't convert response data to string"
    case cantExtractURLFromYoutubeResponse = "Couldn't extract url from youtube response"
    case unkown = "Unknown error occured"
    
    var errorDescription: String? {
        return self.rawValue
    }
}

struct YoutubeError: LocalizedError {
    var errorDescription: String?
    
    init?(errorDescription: String?) {
        guard let errorDescription = errorDescription else {
            return nil
        }
        
        self.errorDescription = errorDescription
    }
}
