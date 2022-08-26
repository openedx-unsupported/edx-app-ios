//
//  NetworkManager+QueuedTask.swift
//  edX
//
//  Created by AsifBilal on 7/29/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

import edXCore

extension NetworkManager {
    
    func performQueuedTasksIfAny(success: Bool, request: URLRequest?, response: HTTPURLResponse?, baseData: Data?, error: NSError?) {
        if queuedTasks.isEmpty { return }
        
        for queuedTask in queuedTasks {
            switch queuedTask {
            case let task as QueuedTask<()>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<UserPreference>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<[UserCourseEnrollment]>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Paginated<[OEXCourse]>>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Paginated<[DiscussionThread]>>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Paginated<[DiscussionComment]>>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Paginated<[Int]>>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Paginated<[BadgeAssertion]>>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<OrderBasket>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<CheckoutBasket>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<OrderVerify>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<[OEXAnnouncement]>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<[UserCourseEnrollment]>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<[String]>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<[DiscussionTopic]>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<OEXCourse>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<UserCourseEnrollment>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<CourseOutline>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<ResumeCourseItem>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<String>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<CourseDateModel>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<CourseDateBannerModel>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<CourseCelebrationModel>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<DiscussionThread>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<DiscussionComment>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<DiscussionInfo>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<UserProfile>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<OEXRegistrationDescription>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<RegistrationFormValidation>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<OEXAccessToken>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<JSON>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<Data>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            case let task as QueuedTask<RemoteImage>:
                performTask(task: task, success: success, request: request, response: response, baseData: baseData, error: error)
                
            default:
                Logger.logInfo(NetworkManager.NETWORK, "Unable to handle task: \(queuedTask)")
            }
        }
        // As we have enqueued all tasks, now remove the tasks.
        removeAllQueuedTasks()
    }
    
    func removeAllQueuedTasks() {
        queuedTasks.removeAll()
    }
    
    private func performTask<T>(task: QueuedTask<T>, success: Bool, request: URLRequest?, response: HTTPURLResponse?, baseData: Data?, error: NSError?) {
        if success {
            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication, reattempting request in queue")
            performTaskForRequest(base: task.base, task.networkRequest, handler: task.handler)
        } else {
            Logger.logInfo(NetworkManager.NETWORK, "Reauthentication unsuccessful so skip attempting for queued request: \(task.networkRequest.path)")
            task.handler(NetworkResult(request: request, response: response, data: nil, baseData: baseData, error: error))
        }
    }
}
