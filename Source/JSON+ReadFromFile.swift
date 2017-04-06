//
//  JSON+ReadFromFile.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 28/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore
import edX

// This is just a class in the current bundle rather than in whatever bundle JSON is in.
// Which allows us to isolate test data to the test bundle
private class BundleClass {}

public extension JSON {
    
    public init(resourceNamed fileName: String) {
        guard let
        url = Bundle(for: type(of: BundleClass())).url(forResource: fileName, withExtension: "json"),
            let data = try? NSData(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe) else
        {
            assertionFailure("Couldn't load data from file")
            self.init([:])
            return
        }
        self.init(data:data as Data)
    }

    public init(plistResourceNamed fileName: String) {
        guard let
            url = Bundle(for: type(of: BundleClass())).url(forResource: fileName, withExtension: "plist"),
            let data = NSDictionary(contentsOf: url) else
        {
            assertionFailure("Couldn't load data from file")
            self.init([:])
            return
        }
        self.init(data)

    }
}
