//
//  ObservableTests.swift
//  edXTests
//
//  Created by Saeed Bashir on 3/25/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import XCTest
@testable import edX

fileprivate class ObserveableTestModel {
    var value: Int
    var observer: Observable<Int>
    
    init(value: Int) {
        self.value = value
        self.observer = Observable(value)
    }
}

class ObservableTests: XCTestCase {
    
    func testObserableNewValue() {
        let model = ObserveableTestModel(value: 3)
        model.observer.subscribe(observer: self) { newValue, oldValue in
            XCTAssert(newValue == 5)
        }
        model.value = 5
    }
    
    func testObserableOldValue() {
        let model = ObserveableTestModel(value: 3)
        model.observer.subscribe(observer: self) { newValue, oldValue in
            XCTAssert(oldValue == 3)
        }
        model.value = 5
    }
}
