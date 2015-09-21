//
//  Logger.swift
//  edX
//
//  Created by Akiva Leffert on 9/11/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol LoggerSink {
    func log(level : Logger.Level, domain : String, message : String, file : String, line : UInt)
}

private class ConsoleLogger : LoggerSink {
    private func log(level: Logger.Level, domain: String, message: String, file : String, line : UInt) {
        let url = NSURL(fileURLWithPath: file)
        NSLog("[\(level.rawValue)|\(domain)] @ \(url.lastPathComponent):\(line) - \(message)")
    }
}

public class Logger : NSObject {
    private let printAllKey = "OEXLoggerPrintAll"
    private let domainsKey = "OEXLoggerDomains"
    
    public static var sharedLogger : Logger = Logger()
    
    public enum Level : String {
        case Debug = "DEBUG" // Never commit anything with this. Easy way to add logs that are obviously meant to be removed
        case Info = "INFO" // For l
        case Error = "ERROR" // For errors that should *always* be printed
        
        private var alwaysPrinted : Bool {
            switch self {
            case .Debug, .Error: return true
            case .Info: return false
            }
        }
    }
    
    public override init() {
        printAll = NSUserDefaults.standardUserDefaults().boolForKey(printAllKey)
        activeDomains = Set(NSUserDefaults.standardUserDefaults().objectForKey(domainsKey) as? [String] ?? [])
        super.init()
    }
    
    private var sinks : [LoggerSink] = [ConsoleLogger()]
    
    public func addSink(sink : LoggerSink) {
        sinks.append(sink)
    }
    
    public var printAll : Bool
        {
        didSet {
            NSUserDefaults.standardUserDefaults().setBool(printAll, forKey: printAllKey)
        }
    }
    
    private var activeDomains : Set<String> {
        didSet {
            domainsChanged()
        }
    }
    
    private func domainsChanged() {
        NSUserDefaults.standardUserDefaults().setObject(Array(activeDomains) as NSArray, forKey: domainsKey)
    }
    
    public func addDomain(domain : String) {
        activeDomains.insert(domain)
        domainsChanged()
    }
    
    public func removeDomain(domain : String) {
        activeDomains.remove(domain)
        domainsChanged()
    }
   
    // Domains are filtered out by default. To enable, hit pause in the debugger and do
    // lldb> call Logger.addDomain(domain)
    public func log(level : Level = .Info, _ domain : String, _ message : String, file : String = __FILE__, line : UInt = __LINE__ ) {
        if (activeDomains.contains(domain) || level.alwaysPrinted) || printAll {
            for sink in sinks {
                sink.log(level, domain: domain, message: message, file:file, line:line)
            }
        }
    }
    
}

// MARK: Static conveniences
extension Logger {

    public static func addDomain(domain : String) {
        sharedLogger.addDomain(domain)
    }
    
    public static func removeDomain(domain : String) {
        sharedLogger.removeDomain(domain)
    }
    
    private static func log(level : Level = .Info, _ domain : String, _ message : String, file : String = __FILE__, line : UInt = __LINE__) {
        sharedLogger.log(level, domain, message, file:file, line:line)
    }
    
    public static func logDebug(domain : String, _ message : String, file : String = __FILE__, line : UInt = __LINE__) {
        sharedLogger.log(.Debug, domain, message, file:file, line:line)
    }
    
    public static func logInfo(domain : String, _ message : String, file : String = __FILE__, line : UInt = __LINE__) {
        sharedLogger.log(.Info, domain, message, file:file, line:line)
    }
    
    public static func logError(domain : String, _ message : String, file : String = __FILE__, line : UInt = __LINE__) {
        sharedLogger.log(.Error, domain, message, file:file, line:line)
    }
}
