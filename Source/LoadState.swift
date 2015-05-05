//
//  LoadState.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

enum LoadState {
    case Initial
    case Loaded
    case Failed(NSError)
}