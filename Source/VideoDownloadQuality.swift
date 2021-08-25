//
//  VideoDownloadQuality.swift
//  edX
//
//  Created by Muhammad Umer on 16/08/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

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
    @objc var preferredEncoding: OEXVideoEncoding? {
        if OEXConfig.shared().isUsingVideoPipeline {
            return getPreferredEncoding()
        } else if let knownEncodings = OEXVideoEncoding.knownEncodingNames() as NSArray as? [String] {
            for name in knownEncodings {
                let encoding = encodings[name] as? OEXVideoEncoding
                if let encoding = encoding {
                    return encoding
                }
            }
        }
        
        // Don't have a known encoding, so return default encoding
        return defaultEncoding
    }
    
    @objc var size: NSNumber? {
        if let preferredEncoding = getPreferredEncoding(), let size = preferredEncoding.size {
            return size
        } else if let knownEncodings = OEXVideoEncoding.knownEncodingNames() as NSArray as? [String] {
            for name in knownEncodings {
                let encoding = encodings[name] as? OEXVideoEncoding
                if encoding?.name != OEXVideoEncodingHLS {
                   return encoding?.size
                }
            }
        }
        return preferredEncoding?.size
    }
    
    @objc var downloadURL: String? {
        var downloadURL: String?
        
        if OEXConfig.shared().isUsingVideoPipeline {
            downloadURL = getPreferredEncoding()?.url
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
    
    private func getPreferredEncoding() -> OEXVideoEncoding? {
        var encoding: OEXVideoEncoding?
        
        let preferredQuality = OEXInterface.shared().getVideoDownladQuality()
        
        // Loop through the available encodings to find a downloadable video URL
        if let supportedEncodings = supportedEncodings as NSArray as? [String],
           let availableEncodings = encodings as? Dictionary<String, OEXVideoEncoding> {
            
            let filteredEncodings = availableEncodings.keys.filter { supportedEncodings.contains($0) }
            
            if filteredEncodings.contains(preferredQuality.rawValue) {
                if preferredQuality == .auto {
                    encoding = getAutoPreferredAvailableURL(filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
                } else {
                    if let possibleEncoding = availableEncodings[preferredQuality.rawValue],
                       let url = possibleEncoding.url, OEXVideoSummary.isDownloadableVideoURL(url) {
                        encoding = possibleEncoding
                    } else {
                        encoding = getFirstAvailableURL(preferredQuality: preferredQuality, filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
                    }
                }
            } else {
                encoding = getFirstAvailableURL(preferredQuality: preferredQuality, filteredEncodings: filteredEncodings, availableEncodings: availableEncodings)
            }
        }
        
        return encoding
    }
    
    private func getEncoding(with availableEncodings: [String : OEXVideoEncoding], possibleEncoding: VideoDownloadQuality) -> OEXVideoEncoding? {
        if let encoding = availableEncodings[possibleEncoding.rawValue],
           let url = encoding.url, OEXVideoSummary.isDownloadableVideoURL(url) {
            return encoding
        } else {
            return nil
        }
    }
    
    private func getAutoPreferredAvailableURL(filteredEncodings: [Dictionary<String, OEXVideoEncoding>.Keys.Element], availableEncodings: [String : OEXVideoEncoding]) -> OEXVideoEncoding? {
        
        var encoding: OEXVideoEncoding?
        
        for possibleEncoding in VideoDownloadQuality.encodings where filteredEncodings.contains(possibleEncoding.rawValue) {
            if let availableEncoding = getEncoding(with: availableEncodings, possibleEncoding: possibleEncoding) {
                encoding = availableEncoding
                break
            }
        }
        
        return encoding
    }
    
    private func getFirstAvailableURL(preferredQuality: VideoDownloadQuality, filteredEncodings: [Dictionary<String, OEXVideoEncoding>.Keys.Element], availableEncodings: [String: OEXVideoEncoding]) -> OEXVideoEncoding? {
        
        var encoding: OEXVideoEncoding?
        
        var possibleEncodings: [VideoDownloadQuality] = []
        
        switch preferredQuality {
        case .desktop:
            possibleEncodings = VideoDownloadQuality.encodings.filter { $0 != preferredQuality }.reversed()
            break
            
        case .mobileHigh, .mobileLow:
            possibleEncodings = VideoDownloadQuality.encodings.filter { $0 != preferredQuality }
            break
            
        default:
            possibleEncodings = VideoDownloadQuality.encodings
            break
        }
        
        for possibleEncoding in possibleEncodings where filteredEncodings.contains(possibleEncoding.rawValue) {
            if let availableEncoding = getEncoding(with: availableEncodings, possibleEncoding: possibleEncoding) {
                encoding = availableEncoding
                break
            }
        }
        
        return encoding
    }
}
