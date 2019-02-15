//
//  SingleChildContainingViewController.swift
//  edX
//
//  Created by Akiva Leffert on 2/23/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class SingleChildContainingViewController : UIViewController {
    override var childForStatusBarStyle: UIViewController? {
        return self.children.last
    }

    override var childForStatusBarHidden: UIViewController? {
        return self.children.last
    }

    override var shouldAutorotate: Bool {
        return self.children.last?.shouldAutorotate ?? super.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return self.children.last?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        view.handleDynamicTypeNotification()        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
