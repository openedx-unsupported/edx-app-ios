//
//  BlockViewControllerCacheManager.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class BlockViewControllerCacheManager: NSObject {
   
    var viewControllers = NSCache()
    private let enableLogs = false
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didRecieveMemoryWarning"), name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    func addToCache(viewController : UIViewController, blockID : CourseBlockID) {
        self.viewControllers.setObject(viewController, forKey: blockID)
        if enableLogs {
            println("ViewController: \(viewController.classForCoder) added for BlockID : \(blockID)")
        }
    }
    
    func getCachedViewControllerForBlockID(blockID : CourseBlockID) -> UIViewController? {
        let viewController = self.viewControllers.objectForKey(blockID) as? UIViewController
        if let vc = viewController {
            if enableLogs {
                println("ViewController: \(vc.classForCoder) returned for BlockID : \(blockID)")
            }
        }
        return viewController
    }
    
    func didRecieveMemoryWarning() {
        if enableLogs {
            println("BlockViewControllerCacheManager did recieve memory warning")
        }
        self.viewControllers.removeAllObjects()
    }
    
    
}
