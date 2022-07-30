//
//  NetworkManager+WaitingTask.swift
//  edX
//
//  Created by AsifBilal on 7/29/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

import edXCore

extension NetworkManager {
    
    func performWaitingTasksIfAny(withReauthenticationResult success: Bool, request: URLRequest?, response: HTTPURLResponse?, originalData: Data?, error: NSError?) {
        if waitingTasks.isEmpty { return}
        
        for waitingTask in waitingTasks {
            switch waitingTask {
            case let task as WaitingTask<()>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
            case let task as WaitingTask<UserPreference>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<[UserCourseEnrollment]>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            default: break
                
            }
        }
        
        // As we have enqueued all tasks, now remove the tasks.
        waitingTasks.removeAll()
    }
    
    private func performTask<T>(task: WaitingTask<T>, withReauthenticationResult success: Bool, request: URLRequest?, response: HTTPURLResponse?, originalData: Data?, error: NSError?) {
        
        if success {
            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication, reattempting request in waiting")
            print("NETWORK:: Reauthentication, reattempting request in waiting request: \(task.networkRequest.path)")
            performTaskForRequest(base: task.base, task.networkRequest, handler: task.handler)
        } else {
            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication unsuccessful so skip attempting for waiting request: \(task.networkRequest.path)")
            print("NETWORK:: Reauthentication unsuccessful so skip attempting for waiting request: \(task.networkRequest.path)")
            task.handler(NetworkResult<T>(request: request, response: response, data: nil, baseData: originalData, error: error))
        }
        
    }
}
