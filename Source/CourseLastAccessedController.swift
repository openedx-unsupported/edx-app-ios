//
//  CourseLastAccessedController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 03/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol CourseLastAccessedControllerDelegate {
    func courseLastAccessedControllerdidFetchLastAccessedItem(item : CourseLastAccessed?)
}

public class CourseLastAccessedController: NSObject {
   
    private let lastAccessedLoader = BackedStream<(CourseBlock, CourseLastAccessed)>()
    private let blockID : CourseBlockID?
    private let dataManager : DataManager
    private let networkManager : NetworkManager
    private let courseQuerier : CourseOutlineQuerier
    
    private var courseID : String {
        return courseQuerier.courseID
    }
    
    public var delegate : CourseLastAccessedControllerDelegate?
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    private var t_hasTriggeredSetLastAccessed = false
    
    
    public init(blockID : CourseBlockID?, dataManager : DataManager, networkManager : NetworkManager, courseQuerier: CourseOutlineQuerier) {
        self.blockID = blockID
        self.dataManager = dataManager
        self.networkManager = networkManager
        self.courseQuerier = courseQuerier
        
        super.init()
        
        addListener()
    }
    
    private var canShowLastAccessed : Bool {
        // We only show at the root level
        return blockID == nil
    }
    
    private var canUpdateLastAccessed : Bool {
        return blockID != nil
    }
    
    public func loadLastAccessed(forMode mode : CourseOutlineMode) {
        if !canShowLastAccessed {
            return
        }
        
        if let firstLoad = dataManager.interface?.getLastAccessedSectionForCourseID(self.courseID) {
            let blockStream = expandAccessStream(Stream(value : firstLoad), forMode : mode)
            lastAccessedLoader.backWithStream(blockStream)
        }
        
        let request = UserAPI.requestLastVisitedModuleForCourseID(courseID)
        let lastAccessed = self.networkManager.streamForRequest(request)
        lastAccessedLoader.backWithStream(expandAccessStream(lastAccessed, forMode : mode))
    }
    
    public func saveLastAccessed() {
        if !canUpdateLastAccessed {
            return
        }
        
        if let currentCourseBlockID = self.blockID {
            t_hasTriggeredSetLastAccessed = true
            let request = UserAPI.setLastVisitedModuleForBlockID(self.courseID, module_id: currentCourseBlockID)
            let courseID = self.courseID
            expandAccessStream(self.networkManager.streamForRequest(request)).extendLifetimeUntilFirstResult {[weak self] result in
                result.ifSuccess() {info in
                    let block = info.0
                    let lastAccessedItem = info.1
                    let interface = self?.dataManager.interface
                    interface?.setLastAccessedSubsectionWith(lastAccessedItem.moduleId,
                        andSubsectionName: block.name,
                        forCourseID: courseID,
                        onTimeStamp: OEXDateFormatting.serverStringWithDate(NSDate()))
                }
            }
        }
    }

    func addListener() {
        lastAccessedLoader.listen(self) {[weak self] info in
            info.ifSuccess {
                let block = $0.0
                var item = $0.1
                item.moduleName = block.name
                
                self?.dataManager.interface?.setLastAccessedSubsectionWith(item.moduleId, andSubsectionName: block.name, forCourseID: self?.courseID, onTimeStamp: OEXDateFormatting.serverStringWithDate(NSDate()))
                self?.delegate?.courseLastAccessedControllerdidFetchLastAccessedItem(item)
            }
            
            info.ifFailure { [weak self] error in
                self?.delegate?.courseLastAccessedControllerdidFetchLastAccessedItem(nil)
            }
        }
        
    }
    
    private func expandAccessStream(stream : Stream<CourseLastAccessed>, forMode mode : CourseOutlineMode = .Full) -> Stream<(CourseBlock, CourseLastAccessed)> {
        return stream.transform {[weak self] lastAccessed in
            return joinStreams(self?.courseQuerier.blockWithID(lastAccessed.moduleId, mode: mode) ?? Stream<CourseBlock>(), Stream(value: lastAccessed))
        }
    }
}




//TESTING
extension CourseLastAccessedController {
    
//    func t_canTriggerShowLastAccessed() -> Bool {
//        return canShowLastAccessed
//    }
//    
//    func t_canTriggerSetLastAccessed() -> Bool {
//        return canUpdateLastAccessed
//    }
}

