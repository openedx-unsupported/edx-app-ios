//
//  IdentifyableCAShapeLayer.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 22/10/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class IdentifyableCAShapeLayer: CAShapeLayer {

    let identifier : String
    
    init(identifier : String) {
        self.identifier = identifier
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        self.identifier = "IBIdentifier"
        super.init(coder: aDecoder)
    }
    
}
