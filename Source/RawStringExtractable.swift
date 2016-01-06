//
//  RawStringExtactable.swift
//  edX
//
//  Created by Akiva Leffert on 10/2/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

protocol RawStringExtractable {
    var rawValue : String { get }
}

extension JSON {
    
    subscript(key : RawStringExtractable) -> JSON {
        return self[key.rawValue]
    }

}

protocol DictionaryExtractionExtension {
    typealias Key
    typealias Value
    subscript(key: Key) -> Value? { get }
}

extension Dictionary: DictionaryExtractionExtension {}

extension DictionaryExtractionExtension where Self.Key == String {
    
    subscript(key : RawStringExtractable) -> Value? {
        return self[key.rawValue]
    }
    
}