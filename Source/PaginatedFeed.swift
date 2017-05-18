//
//  PaginatedFeed.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

//Not conforming to GeneratorType protocol because next() returns -> A NOT ->A?
class PaginatedFeed<A> {
   
    private let generator : (Int) -> A
    private var page = 0
    
    init(f : @escaping (Int) -> A) {
        self.generator = f
    }
    
    func next() -> A? {
        page += 1
        let result = generator(page)
        return result
    }
    
    func current() -> A {
        let result = generator(page)
        return result
    }
}


