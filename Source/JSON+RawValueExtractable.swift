//
//  JSON+RawValueExtractable.swift
//  edX
//
//  Created by Akiva Leffert on 10/2/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

protocol RawValueExtractable {
    var rawValue : String { get }
}

extension JSON {
    
    subscript(value : RawValueExtractable) -> JSON {
        return self[value.rawValue]
    }

}