//
//  MockAnalyticsTracker.swift
//  edX
//
//  Created by Akiva Leffert on 10/2/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edX

public class MockAnalyticsEventRecord : NSObject {
    public let event: OEXAnalyticsEvent
    public let component: String?
    public let properties: [String : AnyObject]
    
    init(event : OEXAnalyticsEvent, component: String?, properties: [String:AnyObject]) {
        self.event = event
        self.component = component
        self.properties = properties
    }
}

public class MockAnalyticsScreenRecord : NSObject {
    public let screenName: String
    public let value: String?
    public let courseID: String?
    public let additionalInfo: NSDictionary?
    
    init(screenName : String, courseID: String?, value: String?, additionalInfo: NSDictionary?) {
        self.screenName = screenName
        self.courseID = courseID
        self.value = value
        self.additionalInfo = additionalInfo
    }
}

enum MockAnalyticsRecord {
    case Screen(MockAnalyticsScreenRecord)
    case Event(MockAnalyticsEventRecord)
    
    var asEvent : MockAnalyticsEventRecord? {
        switch self {
        case .Screen(_): return nil
        case let .Event(e): return e
        }
    }
    
    var asScreen : MockAnalyticsScreenRecord? {
        switch self {
        case let .Screen(s): return s
        case .Event(_): return nil
        }
    }
}

class MockAnalyticsTracker : NSObject, OEXAnalyticsTracker {
    
    private(set) var currentUser: OEXUserDetails? = nil
    private(set) var events: [MockAnalyticsRecord] = []
    
    let eventStream = Sink<MockAnalyticsRecord>()
    
    func identifyUser(user: OEXUserDetails?) {
        currentUser = user
    }
    
    func clearIdentifiedUser() {
        currentUser = nil
    }
    
    func trackEvent(event: OEXAnalyticsEvent, forComponent component: String?, withProperties properties: [String : AnyObject]) {
        let record = MockAnalyticsRecord.Event(MockAnalyticsEventRecord(event: event, component: component, properties: properties))
        events.append(record)
        eventStream.send(record)
    }
    
    func trackScreenWithName(screenName: String, courseID: String?, value: String?, additionalInfo info: [String : String]?) {
        
        let record = MockAnalyticsRecord.Screen(MockAnalyticsScreenRecord(screenName: screenName, courseID: courseID, value: value, additionalInfo: info))
        events.append(record)
        eventStream.send(record)
    }
}
