//
//  DebugMenuLogger.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation



class DebugMenuLogger: NSObject, LoggerSink {

    let filename: String
    private var filehandle: NSFileHandle!

    private class var filename: String {
        let cachesDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        let debugdir = (cachesDir as NSString).stringByAppendingPathComponent("debug")
        if !NSFileManager.defaultManager().fileExistsAtPath(debugdir) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtPath(debugdir, withIntermediateDirectories: true, attributes: nil)
        }
        return debugdir + "/debuglog.txt"
    }

    static let instance = DebugMenuLogger()

    class func setup() {
        if OEXConfig.sharedConfig().shouldShowDebug() {
            Logger.sharedLogger.addSink(instance)
        }
    }

    override init() {
        filename = DebugMenuLogger.filename
        super.init()

        createFile()
        writeToday()
    }

    private func writeToday() {
        let dateStr = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .LongStyle, timeStyle: .LongStyle)
        writeString("-- " + dateStr + " --")
    }

    private func writeString(message: String) {
        let data = (message + "\n").dataUsingEncoding(NSUTF8StringEncoding)!
        filehandle.writeData(data)
    }

    deinit {
        filehandle.closeFile()
    }

    func log(level : Logger.Level, domain : String, message : String, file : String, line : UInt) {
        let url = NSURL(fileURLWithPath: file)
        writeString("[\(level.rawValue)|\(domain)] @ \(url.lastPathComponent!):\(line) - \(message)")
    }

    private func createFile() {
        if !NSFileManager.defaultManager().fileExistsAtPath(filename) {
            NSFileManager.defaultManager().createFileAtPath(filename, contents: nil, attributes: nil)
        }
        filehandle = NSFileHandle(forWritingAtPath: filename)!
        filehandle.seekToEndOfFile()
    }

    private func deleteFile() {
        filehandle.closeFile()
        _ = try? NSFileManager.defaultManager().removeItemAtPath(filename)
    }

    func clear() {
        deleteFile()
        createFile()
        writeToday()
    }
}