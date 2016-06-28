//
//  FileSystemProvider.swift
//  edX
//
//  Created by Michael Katz on 6/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@objc class FileSystemProvider : NSObject {

    static func dataAtURLString(url: String) -> NSData? {
        guard let filePath = OEXFileUtility.filePathForRequestKey(url) else { return nil }
        guard NSFileManager.defaultManager().fileExistsAtPath(filePath) else { return nil }
        return NSData(contentsOfFile: filePath)
    }

    static func deleteVideoFile(videoURL:String) {
        if let filePath = OEXFileUtility.filePathForVideoURL(videoURL, username: OEXSession.sharedSession()?.currentUser?.username) {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(filePath)
        }

        if let requestPath = OEXFileUtility.filePathForRequestKey(videoURL) {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(requestPath)
        }
    }
    
}

