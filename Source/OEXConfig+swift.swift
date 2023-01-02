//
//  OEXConfig.swift
//  edX
//
//  Created by Michael Katz on 1/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

//MARK: - Basic & Helper Operations
extension OEXConfig {

    public subscript(value : RawStringExtractable) -> Any? {
        return self.object(forKey: value.rawValue)
    }

    public subscript(value : String) -> Any? {
        return self.object(forKey: value)
    }

}
