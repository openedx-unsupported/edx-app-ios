//
//  MockAnalyticsTracker.swift
//  edX
//
//  Created by Akiva Leffert on 10/2/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edX

open class MockAnalyticsEventRecord : NSObject {
    open let event: OEXAnalyticsEvent
    open let component: String?
    open let properties: [String : AnyObject]
    
    init(event : OEXAnalyticsEvent, component: String?, properties: [String:AnyObject]) {
        self.event = event
        self.component = component
        self.properties = properties
    }
}

open class MockAnalyticsScreenRecord : NSObject {
    open let screenName: String
    open let value: String?
    open let courseID: String?
    open let additionalInfo: NSDictionary?
    
    init(screenName : String, courseID: String?, value: String?, additionalInfo: NSDictionary?) {
        self.screenName = screenName
        self.courseID = courseID
        self.value = value
        self.additionalInfo = additionalInfo
    }
}

enum MockAnalyticsRecord {
    case screen(MockAnalyticsScreenRecord)
    case event(MockAnalyticsEventRecord)
    
    var asEvent : MockAnalyticsEventRecord? {
        switch self {
        case .screen(_): return nil
        case let .event(e): return e
        }
    }
    
    var asScreen : MockAnalyticsScreenRecord? {
        switch self {
        case let .screen(s): return s
        case .event(_): return nil
        }
    }
}

class MockAnalyticsTracker : NSObject, OEXAnalyticsTracker {
    
    fileprivate(set) var currentUser: OEXUserDetails? = nil
    fileprivate(set) var events: [MockAnalyticsRecord] = []
    
    let eventStream = Sink<MockAnalyticsRecord>()
    
    func identifyUser(_ user: OEXUserDetails?) {
        currentUser = user
    }
    
    func clearIdentifiedUser() {
        currentUser = nil
    }
    
    func trackEvent(_ event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : Any]) {
        let record = MockAnalyticsRecord.event(MockAnalyticsEventRecord(event: event, component: component, properties: properties as [String : AnyObject]))
        events.append(record)
        eventStream.send(record)
    }
    
    func trackScreen(withName screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        
        let record = MockAnalyticsRecord.screen(MockAnalyticsScreenRecord(screenName: screenName, courseID: courseID, value: value, additionalInfo: info as NSDictionary?))
        events.append(record)
        eventStream.send(record)
    }
}
