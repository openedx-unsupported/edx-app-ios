//
//  ProgramConfig.swift
//  edX
//
//  Created by Salman on 01/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

fileprivate enum ProgramKeys: String, RawStringExtractable {
    case ProgramURL = "PROGRAM_URL"
    case ProgramDetailURL = "PROGRAM_DETAIL_URL"
    case ProgramEnabled = "PROGRAM_ENABLED"
}

class ProgramConfig: NSObject {

    let programURL: URL?
    let programDetailURL: String?
    let programEnabled: Bool
   
    init(dictionary: [String:AnyObject]) {
        programURL = (dictionary[ProgramKeys.ProgramURL] as? String).flatMap { URL(string:$0)}
        programDetailURL = dictionary[ProgramKeys.ProgramDetailURL] as? String
        programEnabled = dictionary[ProgramKeys.ProgramEnabled] as? Bool ?? false
    }
}

private let key = "PROGRAM"
extension OEXConfig {
    var programConfig: ProgramConfig {
        return ProgramConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
