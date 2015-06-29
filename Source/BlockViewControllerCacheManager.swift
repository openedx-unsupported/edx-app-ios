//
//  BlockViewControllerCacheManager.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class BlockViewControllerCacheManager: NSObject {
   
    private let viewControllers = NSCache()
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification) { [weak self](_,observer, _) -> Void in
            observer.viewControllers.removeAllObjects()
        }
    }
    
    func addToCache(viewController : UIViewController, blockID : CourseBlockID) {
        self.viewControllers.setObject(viewController, forKey: blockID)
    }
    
    func getCachedViewControllerForBlockID(blockID : CourseBlockID) -> UIViewController? {
        let viewController = self.viewControllers.objectForKey(blockID) as? UIViewController
        return viewController
    }
}
