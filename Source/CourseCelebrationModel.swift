//
//  CourseCelebrationModel.swift
//  edX
//
//  Created by Salman on 10/02/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

enum CelebratoryModelDataKeys: String, RawStringExtractable {
    case firstSection = "first_section"
}

class CourseCelebrationModel: NSObject {
    let fistSection: Bool
    
    init(dictionary:[String:Any]) {
        //let celebrationDictionary = dictionary["celebrations"] as? [String: Any]
        fistSection = dictionary[CelebratoryModelDataKeys.firstSection] as? Bool ?? true
        super.init()
    }
    
    convenience init(json: JSON) {
        let celebrationJson = json["celebrations"]
        
        self.init(dictionary: celebrationJson.dictionaryObject ?? [:])
    }
}
