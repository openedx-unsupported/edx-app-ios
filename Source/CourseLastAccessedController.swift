//
//  CourseLastAccessedController.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 03/07/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public protocol CourseLastAccessedControllerDelegate : class {
    func courseLastAccessedControllerDidFetchLastAccessedItem(item : CourseLastAccessed?)
}

public class CourseLastAccessedController: NSObject {
   
    private let lastAccessedLoader = BackedStream<(CourseBlock, CourseLastAccessed)>()
    private let blockID : CourseBlockID?
    private let dataManager : DataManager
    private let networkManager : NetworkManager
    private let courseQuerier : CourseOutlineQuerier
    private let lastAccessedProvider : LastAccessedProvider?
    private let courseOutlineMode : CourseOutlineMode
    
    private var courseID : String {
        return courseQuerier.courseID
    }
    
    public weak var delegate : CourseLastAccessedControllerDelegate?
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    private var t_hasTriggeredSetLastAccessed = false
    
    
    public init(blockID : CourseBlockID?, dataManager : DataManager, networkManager : NetworkManager, courseQuerier: CourseOutlineQuerier, lastAccessedProvider : LastAccessedProvider? = nil, forMode mode: CourseOutlineMode) {
        self.blockID = blockID
        self.dataManager = dataManager
        self.networkManager = networkManager
        self.courseQuerier = courseQuerier
        self.lastAccessedProvider = lastAccessedProvider ?? dataManager.interface
        courseOutlineMode = mode
        super.init()
        
        addListener()
    }
    
    fileprivate var canShowLastAccessed : Bool {
        // We only show at the root level
        return blockID == nil && courseOutlineMode == .full
    }
    
    fileprivate var canUpdateLastAccessed : Bool {
        return blockID != nil && courseOutlineMode == .full
    }
    
    public func loadLastAccessed(forMode mode: CourseOutlineMode) {
        if !canShowLastAccessed {
            return
        }
        
        if let firstLoad = lastAccessedProvider?.getLastAccessedSectionForCourseID(courseID: self.courseID) {
            let blockStream = expandAccessStream(stream: OEXStream(value : firstLoad), forMode : mode)
            lastAccessedLoader.backWithStream(blockStream)
        }
        let request = UserAPI.requestLastVisitedModuleForCourseID(courseID: courseID)
        let lastAccessed = self.networkManager.streamForRequest(request)
        lastAccessedLoader.backWithStream(expandAccessStream(stream: lastAccessed, forMode : mode))
    }
    
    public func saveLastAccessed() {
        if !canUpdateLastAccessed {
            return
        }
        
        if let currentCourseBlockID = self.blockID {
            t_hasTriggeredSetLastAccessed = true
            let request = UserAPI.setLastVisitedModuleForBlockID(blockID: self.courseID, module_id: currentCourseBlockID)
            let courseID = self.courseID
            expandAccessStream(stream: self.networkManager.streamForRequest(request)).extendLifetimeUntilFirstResult {[weak self] result in
                result.ifSuccess() {info in
                    let block = info.0
                    let lastAccessedItem = info.1
                    
                    if let owner = self {
                        owner.lastAccessedProvider?.setLastAccessedSubSectionWithID(subsectionID: lastAccessedItem.moduleId,
                            subsectionName: block.displayName,
                            courseID: courseID,
                            timeStamp: (DateFormatting.serverString(withDate: NSDate())) ?? "")
                    }
                }
            }
        }
    }

    func addListener() {
        lastAccessedLoader.listen(self) {[weak self] info in
            info.ifSuccess {
                let block = $0.0
                var item = $0.1
                item.moduleName = block.displayName
                
                self?.lastAccessedProvider?.setLastAccessedSubSectionWithID(subsectionID: item.moduleId, subsectionName: block.displayName, courseID: self?.courseID, timeStamp: DateFormatting.serverString(withDate: NSDate()) ?? "")
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(item: item)
            }
            
            info.ifFailure { [weak self] error in
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(item: nil)
            }
        }
        
    }

    private func expandAccessStream(stream: OEXStream<CourseLastAccessed>, forMode mode: CourseOutlineMode = .full) -> OEXStream<(CourseBlock, CourseLastAccessed)> {
        return stream.transform {[weak self] lastAccessed in
            return joinStreams((self?.courseQuerier.blockWithID(id: lastAccessed.moduleId, mode: mode)) ?? OEXStream<CourseBlock>(), OEXStream(value: lastAccessed))
        }
    }
}

extension CourseLastAccessedController {

    public func t_canShowLastAccessed() -> Bool{
        return canShowLastAccessed
    }
    
    public func t_canUpdateLastAccessed() -> Bool{
        return canUpdateLastAccessed
    }
}
