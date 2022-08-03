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
                
            case let task as WaitingTask<Paginated<[OEXCourse]>>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<Paginated<[DiscussionThread]>>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<Paginated<[DiscussionComment]>>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<Paginated<[Int]>>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<Paginated<[BadgeAssertion]>>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<OrderBasket>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<CheckoutBasket>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<OrderVerify>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<[OEXAnnouncement]>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<[UserCourseEnrollment]>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<[String]>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<[DiscussionTopic]>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<OEXCourse>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<UserCourseEnrollment>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<CourseOutline>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<ResumeCourseItem>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<String>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<CourseDateModel>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<CourseDateBannerModel>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<CourseCelebrationModel>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<DiscussionThread>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<DiscussionComment>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<DiscussionInfo>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<UserProfile>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<OEXRegistrationDescription>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<RegistrationFormValidation>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<OEXAccessToken>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<JSON>:
                performTask(task: task, withReauthenticationResult: success, request: request, response: response, originalData: originalData, error: error)
                
            case let task as WaitingTask<Data>:
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
