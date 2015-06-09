//
//  CourseDataManager.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseDataManager: NSObject {
    
    let interface : OEXInterface?
    let networkManager : NetworkManager?
    
    public init(interface : OEXInterface?, networkManager : NetworkManager?) {
        self.interface = interface
        self.networkManager = networkManager
    }
    
    private var queriers : [String:CourseOutlineQuerier] = [:]
    
    public func querierForCourseWithID(courseID : String) -> CourseOutlineQuerier {
        if let querier = queriers[courseID] {
            return querier
        }
        else {
            let querier = CourseOutlineQuerier(courseID: courseID, interface : interface, networkManager : networkManager)
            queriers[courseID] = querier
            return querier
        }
    }
}
