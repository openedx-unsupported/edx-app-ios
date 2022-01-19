
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
        transcripts = []
        
        if transcript.isEmpty {
            completion(false, NSError(domain:"", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Format"]))
            return
        }
        
        let transcriptString = transcript
            .replacingOccurrences(of: "\r\n", with:"\n")
            .replacingOccurrences(of: "\r", with:"\n")
        
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
            var startResult: String?
            var endResult: String?
            var textResult: String?
            
            scanner.scanInt(&indexResult)
            startResult = scanner.scanUpToCharacters(from: .whitespaces)
            _ = scanner.scanUpToString("> ")
            endResult = scanner.scanUpToCharacters(from: .newlines)?
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ">", with: "")
            textResult = scanner.scanUpToString("\"")
            
            if let start = startResult,
               let end = endResult {
                let transcript = TranscriptObject(with: textResult ?? "", start: timeInterval(from: start), end: timeInterval(from: end), index: indexResult)
                transcripts.append(transcript)
            }
        }
        completion(true, nil)
    }
    
    private func timeInterval(from timeString: String) -> TimeInterval {
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var milliSeconds: Int = 0
        
        let splittedByComma = timeString.components(separatedBy: ",")
        
        guard let splittedByColon = splittedByComma.first?.components(separatedBy: ":") else {
            return .zero
        }
        
        for (key, value) in splittedByColon.enumerated() {
            if key == 0 {
                hours = value.intValue
            } else if key == 1 {
                minutes = value.intValue
            } else if key == 2 {
                seconds = value.intValue
            }
        }
        
        milliSeconds = splittedByComma.last?.intValue ?? 0
        
        return (Double(hours) * 3600 + Double(minutes) * 60 + Double(seconds) + Double(Double(milliSeconds) / 1000)) as TimeInterval
    }
}

fileprivate extension String {
    var intValue: Int {
        return Int(Double(self) ?? 0)
    }
}
