//
//  SingleChildContainingViewController.swift
//  edX
//
//  Created by Akiva Leffert on 2/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class SingleChildContainingViewController : UIViewController {
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.childViewControllers.last
    }

    override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.childViewControllers.last
    }

    override var shouldAutorotate: Bool {
        return self.childViewControllers.last?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.childViewControllers.last?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

}
