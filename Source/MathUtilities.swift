//
//  MathUtilities.swift
//  edX
//
//  Created by Salman on 20/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

func doublesWithinEpsilon(left: Double, right: Double) -> Bool {
    return (fabs(left - right) < 0.00001)
}
