
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
            
            if let start = startResult as String?,
                let end = endResult as String?,
                startTimeScanResult, endTimeScanResult, indexScanSuccess, dividerScanSuccess {
                if textLineScanResult, let text = textResult as String? {
                    let transcript = TranscriptObject(with: text, start: timeInterval(from: start), end: timeInterval(from: end), index: indexResult)
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
    
    private func timeInterval(from timeString: String) -> TimeInterval {
        let scanner = Scanner(string: timeString)
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var milliSeconds: Int = 0
        
        // Extract time components from string
        scanner.scanInt(&hours)
        scanner.scanString(":", into: nil)
        scanner.scanInt(&minutes)
        scanner.scanString(":", into: nil)
        scanner.scanInt(&seconds)
        scanner.scanString(",", into: nil)
        scanner.scanInt(&milliSeconds)
        return (Double(hours) * 3600.0 + Double(minutes) * 60.0 + Double(seconds) + Double(Double(milliSeconds)/1000.0)) as TimeInterval
    }
}
