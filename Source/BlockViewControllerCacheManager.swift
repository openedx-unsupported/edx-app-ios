//
//  BlockViewControllerCacheManager.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/06/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class BlockViewControllerCacheManager: NSObject {
   
    var viewControllers = [CourseBlockID : UIViewController]()
    private let enableLogs = false
    
    func addToCache(viewController : UIViewController, blockID : CourseBlockID) {
        if self.viewControllers[blockID] == nil {
            self.viewControllers[blockID] = viewController
            if enableLogs {
                println("ViewController: \(viewController.classForCoder) added for BlockID : \(blockID)")
            }
        }
    }
    
    func getCachedViewControllerForBlockID(blockID : CourseBlockID) -> UIViewController? {
        if let viewController = self.viewControllers[blockID] {
            if enableLogs {
                println("ViewController: \(viewController.classForCoder) returned for BlockID : \(blockID)")
            }
            return viewController
        }
        return nil
    }
    
    func didRecieveMemoryWarning() {
        if enableLogs {
            println("BlockViewControllerCacheManager did recieve memory warning")
        }
        self.viewControllers.removeAll(keepCapacity: false)
    }
    
    
}
