//
//  YoutubeLink.swift
//  Andrey Sevrikov
//
//  Created by Andrey Sevrikov on 04/03/2018.
//  Copyright © 2018 Andrey Sevrikov. All rights reserved.
//

import Foundation

public class YoutubeLink {
    private class var infoBasePrefix: String {
        return "https://www.youtube.com/get_video_info?video_id="
    }
    private class var userAgent: String {
        return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/604.5.6 (KHTML, like Gecko) Version/11.0.3 Safari/604.5.6"
    }
    
    // MARK: - Public
    
    class func extract(for source: ExtractionSource, success: @escaping (VideoInfo) -> Void, failure: @escaping (Swift.Error) -> Void) {
        extractRawInfo(for: source) { info, error in
            
            if let error = error {
                failure(error)
                return
            }
            
            guard info.count > 0 else {
                failure(YoutubeLinkExtractorError.unkown)
                return
            }
            
            success(VideoInfo(rawInfo: info))
        }
    }
    
    // MARK: - Internal
    private class func extractRawInfo(for source: ExtractionSource, completion: @escaping ([[String: String]], Swift.Error?) -> Void) {
        guard let id = source.videoId else {
            completion([], YoutubeLinkExtractorError.cantExtractVideoId)
            return
        }
        
        guard let infoUrl = URL(string: "\(infoBasePrefix)\(id)") else {
            completion([], YoutubeLinkExtractorError.cantConstructRequestUrl)
            return
        }
        
        let r = NSMutableURLRequest(url: infoUrl)
        r.httpMethod = "GET"
        r.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: r as URLRequest) { data, response, error in
            guard let data = data else {
                completion([], error ?? YoutubeLinkExtractorError.noDataInResponse)
                return
            }
            
            guard let dataString = String(data: data, encoding: .utf8) else {
                completion([], YoutubeLinkExtractorError.cantConvertDataToString)
                return
            }
            
            let extractionResult = self.extractInfo(from: dataString)
            completion(extractionResult.0, extractionResult.1)
            
        }.resume()
    }
    
    private class func extractInfo(from string: String) -> ([[String: String]], Swift.Error?) {
        let pairs = string.queryComponents()
        
        guard let playerResponse = pairs["player_response"], !playerResponse.isEmpty else {
            let error = YoutubeError(errorDescription: pairs["reason"])
            return ([], error ?? YoutubeLinkExtractorError.cantExtractURLFromYoutubeResponse)
        }
        
        guard let playerResponseData = playerResponse.data(using: .utf8),
            let playerResponseJSON = (try? JSONSerialization.jsonObject(with: playerResponseData, options: [])) as? [String: Any],
            let streamingData = playerResponseJSON["streamingData"] as? [String: Any],
            let formats = streamingData["formats"] as? [[String: Any]] else {
                return ([], YoutubeLinkExtractorError.cantExtractURLFromYoutubeResponse)
        }
        
        let arrayUrls: [[String: String]] = formats
            .compactMap { $0["url"] as? String }
            .map { ["url": $0] }
        
        return (arrayUrls, nil)
    }
}
