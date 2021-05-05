//
//  CalendarEventManager.swift
//  edX
//
//  Created by Muhammad Umer on 20/04/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation
import EventKit
import EventKitUI


class CalendarManager: NSObject {
    
    private let courseName: String
    private let eventStore = EKEventStore()
    private let calendarNamePrefix = "edX"
    private let iCloudCalendar = "icloud"
    private let startDateOffsetHour: Double = -1
    
    var calendarName: String {
        return calendarNamePrefix + " - " + courseName
    }
    
    private var calender: EKCalendar? {
        return eventStore.calendars(for: .event).filter { $0.title == calendarName }.first
    }
    
    private let calendarColor = OEXStyles.shared().primaryBaseColor()
    
    private var calendarSource: EKSource? {
        let iCloud = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains(iCloudCalendar) })
        let local = eventStore.sources.first(where: { $0.sourceType == .local })
        let fallback = eventStore.defaultCalendarForNewEvents?.source
        
        return iCloud ?? local ?? fallback
    }
    
    private var courseCalendar: EKCalendar {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = calendarColor.cgColor
        calendar.source = calendarSource
        
        return calendar
    }
    
    var isAuthorized: Bool {
        return authorizationStatus == .authorized
    }
    
    var authorizationStatus: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    required init(courseName: String) {
        self.courseName = courseName
    }
    
    func requestAccess(completion: @escaping (Bool, Error?, EKAuthorizationStatus) -> ()) {
        eventStore.requestAccess(to: .event) { [weak self] access, error in
            guard let weakSelf = self, access else {
                completion(false, error, EKEventStore.authorizationStatus(for: .event))
                return
            }
            
            if let _ = weakSelf.calender {
                DispatchQueue.main.async {
                    completion(true, error, weakSelf.authorizationStatus)
                }
            } else {
                do {
                    try weakSelf.eventStore.saveCalendar(weakSelf.courseCalendar, commit: true)
                    DispatchQueue.main.async {
                        completion(access, error, weakSelf.authorizationStatus)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        completion(access, error, weakSelf.authorizationStatus)
                    }
                }
            }
        }
    }
    
    func addEventsToCalendar(for dateBlocksMap: [Date : [CourseDateBlock]], completion: @escaping (Bool, Error?) -> ()) {
        var events: [EKEvent] = []
        
        for item in dateBlocksMap where item.key > Date() {
            let blocks = item.value
            
            if blocks.count > 1 {
                if let generatedEvent = generateCalendarEvent(for: blocks) {
                    events.append(generatedEvent)
                }
            } else {
                if let first = blocks.first {
                    let generatedEvent = generateCalendarEvent(for: first)
                    events.append(generatedEvent)
                }
            }
        }
                
        if events.isEmpty {
            DispatchQueue.main.async {
                completion(false, nil)
            }
        } else {
            events.forEach { event in addEvent(event: event) }
            do {
                try eventStore.commit()
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
    
    func removeCalendar(completion: ((Bool, Error?) -> ())? = nil) {
        if let calendar = calender {
            do {
                try eventStore.removeCalendar(calendar, commit: true)
                DispatchQueue.main.async {
                    completion?(true, nil)
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion?(false, error)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion?(false, nil)
            }
        }
    }
    
    private func generateCalendarEvent(for block: CourseDateBlock) -> EKEvent {
        let title = block.title + ": " + courseName
        let startDate = block.blockDate.add(hours: startDateOffsetHour)
        let endDate = block.blockDate
        let alarm = EKAlarm(absoluteDate: startDate)
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calender
        event.notes = "\(courseName) \n \(block.title)"
        event.addAlarm(alarm)
        
        return event
    }
    
    private func generateCalendarEvent(for blocks: [CourseDateBlock]) -> EKEvent? {
        
        guard let firstBlock = blocks.first else { return nil }
        
        let title = firstBlock.title + ": " + courseName
        let startDate = firstBlock.blockDate.add(hours: startDateOffsetHour)
        let endDate = firstBlock.blockDate
        let alarm = EKAlarm(absoluteDate: startDate)
        
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calender
                
        let notes = "\(courseName) \n" + blocks.compactMap { $0.title }.joined(separator: ", ")
        
        event.notes = notes
        event.addAlarm(alarm)
        
        return event
    }
    
    private func addEvent(event: EKEvent) {
        if !alreadyExists(event: event) {
            try? eventStore.save(event, span: .thisEvent)
        }
    }
    
    private func alreadyExists(event eventToAdd: EKEvent) -> Bool {
        let calendars = eventStore.calendars(for: .event).filter { $0.title == calendarName }
        let predicate = eventStore.predicateForEvents(withStart: eventToAdd.startDate, end: eventToAdd.endDate, calendars: calendars)
        let existingEvents = eventStore.events(matching: predicate)
        
        return existingEvents.contains { event -> Bool in
            return eventToAdd.title == event.title
                && event.startDate == eventToAdd.startDate
                && event.endDate == eventToAdd.endDate
        }
    }
}

fileprivate extension Date {
    func add(minutes: Double) -> Date {
        addingTimeInterval(minutes * 60)
    }
    
    func add(hours: Double) -> Date {
        add(minutes: hours * 60)
    }
}
