//
//  FileSystemProvider.swift
//  edX
//
//  Created by Michael Katz on 6/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@objc class FileSystemProvider : NSObject {

    static func dataForURLKey(url: String) -> NSData? {
        guard let filePath = OEXFileUtility.filePathForRequestKey(url) else { return nil }
        guard NSFileManager.defaultManager().fileExistsAtPath(filePath) else { return nil }
        return NSData(contentsOfFile: filePath)
    }

    static func updateData(data: NSData, url: String) {
        guard let filePath = OEXFileUtility.filePathForRequestKey(url) else { return }
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) && NSFileManager.defaultManager().isDeletableFileAtPath(filePath) {
            do {
                _ = try NSFileManager.defaultManager().removeItemAtPath(filePath)
            } catch {
                Logger.logError("STORAGE", "Error removing file at path \(error)")
            }
        }

        data.writeToFile(filePath, atomically: true)
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
