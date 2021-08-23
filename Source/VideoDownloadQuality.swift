//
//  VideoDownloadQuality.swift
//  edX
//
//  Created by Muhammad Umer on 16/08/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

let NOTIFICATION_VIDEO_DOWNLOAD_QUALITY_CHANGED = "VideoDownloadQuality"

private let OEXVideoDownloadQuality = "OEXVideoDownloadQuality"

enum VideoDownloadQuality: CaseIterable {
    case auto
    case mobileLow // 640 x 360 - 360p
    case mobileHigh // 960 x 540 - 540p
    case desktop // 1280 x 720 - 720p
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .auto:
            return OEXVideoEncodingHLS
        case .mobileLow:
            return OEXVideoEncodingMobileLow
        case .mobileHigh:
            return OEXVideoEncodingMobileHigh
        case .desktop:
            return OEXVideoEncodingDesktopMP4
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case OEXVideoEncodingHLS:
            self = .auto
        case OEXVideoEncodingMobileLow:
            self = .mobileLow
        case OEXVideoEncodingMobileHigh:
            self = .mobileHigh
        case OEXVideoEncodingDesktopMP4:
            self = .desktop
        default:
            self = .auto
        }
    }
    
    var title: String {
        switch self {
        case .auto:
            return Strings.VideoDownloadQuality.auto
            
        case .mobileLow:
            return Strings.VideoDownloadQuality.low
            
        case .mobileHigh:
            return Strings.VideoDownloadQuality.medium
            
        case .desktop:
            return Strings.VideoDownloadQuality.high
        }
    }
    
    var analyticsValue: String {
        switch self {
        case .auto:
            return "auto"
            
        case .mobileLow:
            return "360p"
            
        case .mobileHigh:
            return "540p"
            
        case .desktop:
            return "720p"
        }
    }
    
    static var encodings: [VideoDownloadQuality] {
        return [.mobileLow, .mobileHigh, .desktop]
    }
}

extension OEXInterface {
    func saveVideoDownloadQuality(quality: VideoDownloadQuality) {
        UserDefaults.standard.set(quality.rawValue, forKey: OEXVideoDownloadQuality)
        UserDefaults.standard.synchronize()
    }
    
    func getVideoDownladQuality() -> VideoDownloadQuality {
        if let value = UserDefaults.standard.value(forKey: OEXVideoDownloadQuality) as? String,
           let quality = VideoDownloadQuality(rawValue: value) {
            return quality
        } else {
            return .auto
        }
    }
}

extension OEXVideoSummary {
    @objc var downloadURL: String? {
        var downloadURL: String?
        
        if OEXConfig.shared().isUsingVideoPipeline {
            downloadURL = getPreferredDownloadURL()
        } else {
            if let videoURL = videoURL, OEXVideoSummary.isDownloadableVideoURL(videoURL) {
                downloadURL = videoURL
            } else {
                // Loop through the video sources to find a downloadable video URL
                guard let allSources = allSources as NSArray as? [String] else { return nil }
                for url in allSources where OEXVideoSummary.isDownloadableVideoURL(url) {
                    downloadURL = url
                    break
                }
            }
        }
        
        return downloadURL
    }
    
    private func getPreferredDownloadURL() -> String? {
        var downloadURL: String?
        
        let preferredQuality = OEXInterface.shared().getVideoDownladQuality()
        
        // Loop through the available encodings to find a downloadable video URL
        if let supportedEncodings = supportedEncodings as NSArray as? [String],
           let availableEncodings = encodings as? Dictionary<String, OEXVideoEncoding> {
            
            let filteredEncodings = availableEncodings.keys.filter { supportedEncodings.contains($0) }
            
            if filteredEncodings.contains(preferredQuality.rawValue) {
                if preferredQuality == .auto {
                    downloadURL = getAutoPreferredAvailableURL(filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
                } else {
                    if let encoding = availableEncodings[preferredQuality.rawValue],
                       let url = encoding.url, OEXVideoSummary.isDownloadableVideoURL(url) {
                        downloadURL = url
                    } else {
                        downloadURL = getFirstAvailableURL(preferredQuality: preferredQuality, filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
                    }
                }
            } else {
                downloadURL = getFirstAvailableURL(preferredQuality: preferredQuality, filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
            }
        }
        
        return downloadURL
    }
    
    private func url(with availableEncodings: [String : OEXVideoEncoding], quality: VideoDownloadQuality) -> String? {
        if let encoding = availableEncodings[quality.rawValue],
           let url = encoding.url, OEXVideoSummary.isDownloadableVideoURL(url) {
            return url
        } else {
            return nil
        }
    }
    
    private func getAutoPreferredAvailableURL(filteredEncodings: [Dictionary<String, OEXVideoEncoding>.Keys.Element], availableEncodings: [String : OEXVideoEncoding]) -> String? {
        
        var downloadURL: String?
        
        for encoding in VideoDownloadQuality.encodings where filteredEncodings.contains(encoding.rawValue) {
            if let url = url(with: availableEncodings, quality: encoding) {
                downloadURL = url
                break
            }
        }
        
        return downloadURL
    }
    
    private func getFirstAvailableURL(preferredQuality: VideoDownloadQuality, filteredEncodings: [Dictionary<String, OEXVideoEncoding>.Keys.Element], availableEncodings: [String: OEXVideoEncoding]) -> String? {
        
        var downloadURL: String?
        
        var possibleEncodings: [VideoDownloadQuality] = []
        
        switch preferredQuality {
        case .desktop:
            possibleEncodings = [.mobileHigh, .mobileLow]
            break
            
        case .mobileHigh:
            possibleEncodings = [.mobileLow, .desktop]
            break
            
        case .mobileLow:
            possibleEncodings = [.mobileHigh, .desktop]
            break
            
        default:
            possibleEncodings = VideoDownloadQuality.encodings
            break
        }
        
        for encoding in possibleEncodings where filteredEncodings.contains(encoding.rawValue) {
            if let url = url(with: availableEncodings, quality: encoding) {
                downloadURL = url
                break
            }
        }
        
        return downloadURL
    }
}
