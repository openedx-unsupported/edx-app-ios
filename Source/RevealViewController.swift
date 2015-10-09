//
//  RevealViewController.swift
//  edX
//
//  Created by Akiva Leffert on 9/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class RevealViewController: SWRevealViewController {
    
    override init!(rearViewController: UIViewController!, frontViewController: UIViewController!) {
        super.init(rearViewController: rearViewController, frontViewController: frontViewController)
        self.rearViewRevealWidth = 300
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rearViewRevealWidth = 300
    }
    
    func loadStoryboardControllers() {
        // Do nothing. Just want to remove parent behavior
    }

}
