//
//  Logger.swift
//  edX
//
//  Created by Akiva Leffert on 9/11/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol LoggerSink {
    func log(_ level : Logger.Level, domain : String, message : String, file : String, line : UInt)
    /** Set to `true` to ignore print filters */
    var alwaysPrint: Bool { get }
}

public extension LoggerSink {
    var alwaysPrint: Bool { return false }
}

private class ConsoleLogger : LoggerSink {
    fileprivate func log(_ level: Logger.Level, domain: String, message: String, file : String, line : UInt) {
        let url = URL(fileURLWithPath: file)
        print("[\(level.rawValue)|\(domain)] @ \(url.lastPathComponent):\(line) - \(message)")
    }
}

open class Logger : NSObject {
    fileprivate let printAllKey = "OEXLoggerPrintAll"
    fileprivate let domainsKey = "OEXLoggerDomains"
    
    open static var sharedLogger : Logger = Logger()
    
    public enum Level : String {
        case Debug = "DEBUG" // Never commit anything with this. Easy way to add logs that are obviously meant to be removed
        case Info = "INFO" // For l
        case Error = "ERROR" // For errors that should *always* be printed
        
        fileprivate var alwaysPrinted : Bool {
            switch self {
            case .Debug, .Error: return true
            case .Info: return false
            }
        }
    }
    
    public override init() {
        printAll = UserDefaults.standard.bool(forKey: printAllKey)
        activeDomains = Set(UserDefaults.standard.object(forKey: domainsKey) as? [String] ?? [])
        super.init()
    }
    
    fileprivate var sinks : [LoggerSink] = [ConsoleLogger()]
    
    open func addSink(_ sink : LoggerSink) {
        sinks.append(sink)
    }
    
    open var printAll : Bool
        {
        didSet {
            UserDefaults.standard.set(printAll, forKey: printAllKey)
        }
    }
    
    fileprivate var activeDomains : Set<String> {
        didSet {
            domainsChanged()
        }
    }
    
    fileprivate func domainsChanged() {
        UserDefaults.standard.set(Array(activeDomains) as NSArray, forKey: domainsKey)
    }
    
    open func addDomain(_ domain : String) {
        activeDomains.insert(domain)
        domainsChanged()
    }
    
    open func removeDomain(_ domain : String) {
        activeDomains.remove(domain)
        domainsChanged()
    }
   
    // Domains are filtered out by default. To enable, hit pause in the debugger and do
    // lldb> call Logger.addDomain(domain)
    open func log(_ level : Level = .Info, _ domain : String, _ message : String, file : String = #file, line : UInt = #line ) {
        for sink in sinks {
            if (activeDomains.contains(domain) || level.alwaysPrinted) || printAll || sink.alwaysPrint {
                sink.log(level, domain: domain, message: message, file:file, line:line)
            }
        }
    }

}

// MARK: Static conveniences
extension Logger {

    public static func addDomain(_ domain : String) {
        sharedLogger.addDomain(domain)
    }
    
    public static func removeDomain(_ domain : String) {
        sharedLogger.removeDomain(domain)
    }
    
    fileprivate static func log(_ level : Level = .Info, _ domain : String, _ message : String, file : String = #file, line : UInt = #line) {
        sharedLogger.log(level, domain, message, file:file, line:line)
    }
    
    public static func logDebug(_ domain : String, _ message : String, file : String = #file, line : UInt = #line) {
        sharedLogger.log(.Debug, domain, message, file:file, line:line)
    }
    
    public static func logInfo(_ domain : String, _ message : String, file : String = #file, line : UInt = #line) {
        sharedLogger.log(.Info, domain, message, file:file, line:line)
    }
    
    public static func logError(_ domain : String, _ message : String, file : String = #file, line : UInt = #line) {
        sharedLogger.log(.Error, domain, message, file:file, line:line)
    }
}
