//
//  VideoDownloadQuality.swift
//  edX
//
//  Created by Muhammad Umer on 16/08/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

private let VideoDownloadQualityKey = "OEXVideoDownloadQuality"

@objc public enum VideoDownloadQuality: Int {
    case auto
    case mobileLow // OEXVideoEncodingMobileLow 640 x 360 - 360p
    case mobileHigh // OEXVideoEncodingMobileHigh 960 x 540 - 540p
    case desktop // OEXVideoEncodingDesktopMP4 1280 x 720 - 720p
    
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
            return Strings.videoDownloadQualityAuto
            
        case .mobileLow:
            return Strings.videoDownloadQualityLow
            
        case .mobileHigh:
            return Strings.videoDownloadQualityMedium
            
        case .desktop:
            return Strings.videoDownloadQualityHigh
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
    
    static var allCases: [VideoDownloadQuality] {
        return [.auto, .mobileLow, .mobileHigh, .desktop]
    }
}

extension OEXInterface {
    func saveVideoDownloadQuality(quality: VideoDownloadQuality) {
        UserDefaults.standard.set(quality.rawValue, forKey: VideoDownloadQualityKey)
        UserDefaults.standard.synchronize()
    }
    
    @objc func getVideoDownladQuality() -> VideoDownloadQuality {
        if let value = UserDefaults.standard.value(forKey: VideoDownloadQualityKey) as? String,
           let quality = VideoDownloadQuality(rawValue: value) {
            return quality
        } else {
            return .auto
        }
    }
}
