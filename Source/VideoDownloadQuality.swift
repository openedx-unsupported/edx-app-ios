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
    @objc var size: NSNumber? {
        if let encoding = getPreferredEncoding(), let size = encoding.size {
            return size
        } else {
            guard let supportedencodings = OEXVideoEncoding.knownEncodingNames() as NSArray as? [String] else { return nil }
            for name in supportedencodings {
                if let encoding = encodings[name] as? OEXVideoEncoding {
                    if encoding.name != OEXVideoEncodingHLS {
                        return encoding.size
                    }
                }
            }
            return preferredEncoding?.size
        }
    }
    
    @objc var downloadURL: String? {
        if let encoding = getPreferredEncoding(), let url = encoding.url {
            return url
        } else {
            if let videoURL = videoURL, OEXVideoSummary.isDownloadableVideoURL(videoURL) {
                return videoURL
            } else {
                // Loop through the video sources to find a downloadable video URL
                guard !allSources.isEmpty, let allSources = allSources as NSArray as? [String] else { return nil }
                for url in allSources {
                    if OEXVideoSummary.isDownloadableVideoURL(url) {
                        return url
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getPreferredEncoding() -> OEXVideoEncoding? {
        if OEXConfig.shared().isUsingVideoPipeline {
            // Loop through the available encodings to find a downloadable video URL
            if let supportedEncodings = supportedEncodings as NSArray as? [String],
               let availableEncodings = encodings as? Dictionary<String, OEXVideoEncoding> {
                
                let preferredDownloadQuality = OEXInterface.shared().getVideoDownladQuality()
                
                if preferredDownloadQuality == .auto {
                    if let url = findPossibleEncodingIfAvailable(preferredDownloadQuality, availableEncodings) {
                        return url
                    }
                } else if availableEncodings.keys.contains(where: { $0 == preferredDownloadQuality.rawValue }) {
                    return availableEncodings[preferredDownloadQuality.rawValue]
                } else {
                    if let encoding = findPossibleEncodingIfAvailable(preferredDownloadQuality, availableEncodings) {
                        return encoding
                    } else {
                        for name in supportedEncodings {
                            if let encoding = availableEncodings[name], let url = encoding.url {
                                if OEXVideoSummary.isDownloadableVideoURL(url) {
                                    return encoding
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private func findPossibleEncodingIfAvailable(_ preferredDownloadQuality: VideoDownloadQuality, _ availableEncodings: [String : OEXVideoEncoding]) -> OEXVideoEncoding? {
        var possibleEncodings: [VideoDownloadQuality] = []
        
        switch preferredDownloadQuality {
        case .desktop:
            possibleEncodings = VideoDownloadQuality.encodings.filter { $0 != preferredDownloadQuality }.reversed()
            
        case .mobileHigh, .mobileLow:
            possibleEncodings = VideoDownloadQuality.encodings.filter { $0 != preferredDownloadQuality }
            
        default:
            possibleEncodings = VideoDownloadQuality.allCases
        }
        
        for possibleEncoding in possibleEncodings {
            if let encoding = availableEncodings[possibleEncoding.rawValue], let url = encoding.url, OEXVideoSummary.isDownloadableVideoURL(url) {
                return encoding
            }
        }
        
        return nil
    }
}
