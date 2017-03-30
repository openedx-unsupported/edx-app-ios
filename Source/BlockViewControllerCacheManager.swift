//
//  BlockViewControllerCacheManager.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class BlockViewControllerCacheManager: NSObject {
   
    private let viewControllers = NSCache<AnyObject, AnyObject>()
    
    override init() {
        super.init()
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning.rawValue) {(_,observer, _) -> Void in
            observer.viewControllers.removeAllObjects()
        }
    }
    
    func addToCache(viewController : UIViewController, blockID : CourseBlockID) {
        self.viewControllers.setObject(viewController, forKey: blockID as AnyObject)
    }
    
    func getCachedViewControllerForBlockID(blockID : CourseBlockID) -> UIViewController? {
        let viewController = self.viewControllers.object(forKey: blockID as AnyObject) as? UIViewController
        return viewController
    }
    
    func cacheHitForBlockID(blockID : CourseBlockID) -> Bool {
        return self.viewControllers.object(forKey: blockID as AnyObject) != nil
    }
}
