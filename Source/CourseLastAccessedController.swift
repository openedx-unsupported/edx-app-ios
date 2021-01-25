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
                
        if let firstLoad = lastAccessedProvider?.getLastAccessedBlock(for: courseID) {
            let blockStream = expandAccessStream(stream: OEXStream(value : firstLoad), forMode : mode)
            lastAccessedLoader.backWithStream(blockStream)
        }
        let request = UserAPI.requestLastVisitedModuleForCourseID(courseID: courseID)
        let lastAccessed = networkManager.streamForRequest(request)
        lastAccessedLoader.backWithStream(expandAccessStream(stream: lastAccessed, forMode : mode))
    }
    
    private func markBlockAsComplete(block: CourseBlock) {
        guard let username = OEXSession.shared()?.currentUser?.username else { return }
        let networkRequest = UserAPI.setBlockCompletionRequest(username: username, courseID: courseID, blockID: block.blockID)
        networkManager.taskForRequest(networkRequest) { _ in }
    }
    
    public func saveLastAccessed(block: CourseBlock) {
        if !canUpdateLastAccessed {
            return
        }
        
        markBlockAsComplete(block: block)
    }

    func addListener() {
        lastAccessedLoader.listen(self) { [weak self] info in
            switch info {
            case .success((let block, let lastAccessedItem)):
                self?.lastAccessedProvider?.setLastAccessedBlock(with: lastAccessedItem.lastVisitedBlockID, lastVisitedBlockName: block.displayName, courseID: self?.courseID, timeStamp: DateFormatting.serverString(withDate: NSDate()) ?? "")
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(item: lastAccessedItem)
                
                break
            case .failure:
                self?.delegate?.courseLastAccessedControllerDidFetchLastAccessedItem(item: nil)
                
                break
            }
        }
    }

    private func expandAccessStream(stream: OEXStream<CourseLastAccessed>, forMode mode: CourseOutlineMode = .full) -> OEXStream<(CourseBlock, CourseLastAccessed)> {
        return stream.transform { [weak self] lastAccessed in
            return joinStreams((self?.courseQuerier.blockWithID(id: lastAccessed.lastVisitedBlockID, mode: mode)) ?? OEXStream<CourseBlock>(), OEXStream(value: lastAccessed))
        }
    }
}

extension CourseLastAccessedController {

    public func t_saveLastAccess(item: CourseLastAccessed) {
        lastAccessedProvider?.setLastAccessedBlock(with: item.lastVisitedBlockID, lastVisitedBlockName: item.lastVisitedBlockName, courseID: courseID, timeStamp: DateFormatting.serverString(withDate: NSDate()) ?? "")
        t_hasTriggeredSetLastAccessed = true
    }
    
    public func t_getLastAccessFor(courseID: String) -> CourseLastAccessed? {
        return lastAccessedProvider?.getLastAccessedBlock(for: courseID)
    }
    
    public func t_canShowLastAccessed() -> Bool{
        return canShowLastAccessed
    }
    
    public func t_canUpdateLastAccessed() -> Bool{
        return canUpdateLastAccessed
    }
}
