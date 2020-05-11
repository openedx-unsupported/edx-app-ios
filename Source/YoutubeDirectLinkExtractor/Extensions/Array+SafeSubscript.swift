//
//  Array+SafeSubscript.swift
//  vkSpy
//
//  Created by Andrey Sevrikov on 24/09/2017.
//  Copyright © 2017 devandsev. All rights reserved.
//

import Foundation

extension Array {
    
    subscript (safe index: Int) -> Element? {
        return Int(index) < count ? self[Int(index)] : nil
    }
}
