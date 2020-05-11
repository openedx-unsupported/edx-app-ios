//
//  String+Components.swift
//  YoutubeDirectLinkExtractor
//
//  Created by Andrey Sevrikov on 04/03/2018.
//  Copyright © 2018 Andrey Sevrikov. All rights reserved.
//

import Foundation

extension String {
    
    func queryComponents() -> [String: String] {
        var pairs: [String: String] = [:]
        
        for pair in self.components(separatedBy: "&") {
            let pairArr = pair.components(separatedBy: "=")
            
            guard pairArr.count == 2,
            let key = pairArr.first?.decodedFromUrl(),
            let value = pairArr.last?.decodedFromUrl() else {
                continue
            }
            
            pairs[key] = value
        }
        
        return pairs
    }
    
    func decodedFromUrl() -> String? {
        return self.replacingOccurrences(of: "+", with: " ").removingPercentEncoding
    }
}
