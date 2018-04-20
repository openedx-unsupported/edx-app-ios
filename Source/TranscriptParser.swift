
//
//  TranscriptParser.swift
//  edX
//
//  Created by Salman on 13/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

typealias SubTitleParsingCompletion = (_ parsed: Bool,_ error: Error?) -> Void

struct TranscriptObject {
    var text: String
    var start: TimeInterval
    var end: TimeInterval
    var index: Int
    
    init(with text: String, start: TimeInterval, end: TimeInterval, index: Int) {
        self.text = text
        self.start = start
        self.end = end
        self.index = index
    }
}

class TranscriptParser: NSObject {
    
    private(set) var transcripts: [TranscriptObject] = []
    
    func parse(transcript: String, completion: SubTitleParsingCompletion) {
        transcripts.removeAll()
        if transcript.isEmpty {
            completion(false, NSError(domain:"", code:-1, userInfo:[ NSLocalizedDescriptionKey: "Invalid Format"]))
            return
        }
        
        let transcriptString = transcript.replacingOccurrences(of: "\r", with:"\n")
        var components = transcriptString.components(separatedBy: "\r\n\r\n")
        
        // Fall back to \n\n separation
        if components.count == 1 {
            components = transcriptString.components(separatedBy: "\n\n")
        }
        
        for component in components {
            if component.isEmpty {
                continue
            }
            
            let scanner = Scanner(string: component)
            var indexResult: Int = -1
            var startResult: NSString?
            var endResult: NSString?
            var textResult: NSString?
            
            let indexScanSuccess = scanner.scanInt(&indexResult)
            let startTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.whitespaces, into: &startResult)
            let dividerScanSuccess = scanner.scanUpTo("> ", into: nil)
            if scanner.scanLocation + 2 < component.count {
                scanner.scanLocation += 2
            }
            let endTimeScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &endResult)
            var textLineScanResult = false
            if scanner.scanLocation + 1 < component.count {
                scanner.scanLocation += 1
                textLineScanResult = scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &textResult)
            }
            
            if let start = startResult,
                let end = endResult,
                let startTimeInterval = timeInterval(from: start as String),
                let endTimeInterval = timeInterval(from: end as String),
                startTimeScanResult, endTimeScanResult, indexScanSuccess, dividerScanSuccess {
                if textLineScanResult, let text = textResult {
                    let transcript = TranscriptObject(with: text as String, start: startTimeInterval, end: endTimeInterval, index: indexResult)
                    transcripts.append(transcript)
                }
            }
            else {
                completion(false, NSError(domain:"", code:-1, userInfo:[ NSLocalizedDescriptionKey: "Invalid Format"]))
                return
            }
            
        }
        completion(true, nil)
    }
    
    private func timeInterval(from timeString: String) -> TimeInterval? {
        let scanner = Scanner(string: timeString)
        var hoursResult: Int = 0
        var minutesResult: Int = 0
        var secondsResult: NSString?
        var millisecondsResult: NSString?
        
        // Extract time components from string
        scanner.scanInt(&hoursResult)
        scanner.scanLocation += 1
        scanner.scanInt(&minutesResult)
        scanner.scanLocation += 1
        scanner.scanUpTo(",", into: &secondsResult)
        scanner.scanLocation += 1
        scanner.scanUpToCharacters(from: CharacterSet.newlines, into: &millisecondsResult)
        
        if let secondsString = secondsResult as String?,
            let seconds = Int(secondsString),
            let millisecondsString = millisecondsResult as String?,
            let milliseconds = Int(millisecondsString) {
            let timeInterval: Double = Double(hoursResult) * 3600.0 + Double(minutesResult) * 60.0 + Double(seconds) + Double(Double(milliseconds)/1000.0)
            return timeInterval as TimeInterval
        }
        return nil
    }
}
