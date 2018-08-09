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
    case ProgramDetailURLTemplate = "PROGRAM_DETAIL_URL_TEMPLATE"
    case Enabled = "ENABLED"
}

class ProgramConfig: NSObject {

    let programURL: URL?
    let programDetailURLTemplate: String?
    let enabled: Bool
   
    init(dictionary: [String:AnyObject]) {
        programURL = (dictionary[ProgramKeys.ProgramURL] as? String).flatMap { URL(string:$0)}
        programDetailURLTemplate = dictionary[ProgramKeys.ProgramDetailURLTemplate] as? String
        enabled = dictionary[ProgramKeys.Enabled] as? Bool ?? false
    }
}

private let key = "PROGRAM"
extension OEXConfig {
    var programConfig: ProgramConfig {
        return ProgramConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
