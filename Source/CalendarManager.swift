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

struct CourseCalendar: Codable {
    let identifier: String
    let courseID: String
    var isOn: Bool
}

class CalendarManager: NSObject {
    
    private let courseName: String
    private let courseID: String
    
    private let eventStore = EKEventStore()
    private let iCloudCalendar = "icloud"
    private let startDateOffsetHour: Double = -1
    private var calendarKey = "CalendarEntries"
    
    private var localCalendar: EKCalendar? {
        guard let courseCalendar = calendarEntry else {
            return eventStore.calendars(for: .event).filter { $0.title == courseName }.first
        }
        return eventStore.calendars(for: .event).filter { $0.calendarIdentifier == courseCalendar.identifier }.first
    }
    
    private let calendarColor = OEXStyles.shared().primaryBaseColor()
    
    private var calendarSource: EKSource? {
        let iCloud = eventStore.sources.first(where: { $0.sourceType == .calDAV && $0.title.localizedCaseInsensitiveContains(iCloudCalendar) })
        let local = eventStore.sources.first(where: { $0.sourceType == .local })
        let fallback = eventStore.defaultCalendarForNewEvents?.source
        
        return iCloud ?? local ?? fallback
    }
        
    private func calendar() -> EKCalendar {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = calendarName
        calendar.cgColor = calendarColor.cgColor
        calendar.source = calendarSource
        
        return calendar
    }
    
    var authorizationStatus: EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }
    
    var calendarName: String {
        return OEXConfig.shared().platformName() + " - " + courseName
    }
    
    var calendarState: Bool {
        set {
            updateCalendarState(isOn: newValue)
        }
        get {
            if let calendarEntry = calendarEntry,
               let localCalendar = localCalendar {
                if calendarEntry.identifier == localCalendar.calendarIdentifier {
                    return calendarEntry.isOn
                }
            }
            return false
        }
    }
    
    required init(courseID: String, courseName: String) {
        self.courseID = courseID
        self.courseName = courseName
    }
    
    func requestAccess(completion: @escaping (Bool, EKAuthorizationStatus, EKAuthorizationStatus) -> ()) {
        let previousStatus = EKEventStore.authorizationStatus(for: .event)
        eventStore.requestAccess(to: .event) { access, _ in
            let currentStatus = EKEventStore.authorizationStatus(for: .event)
            DispatchQueue.main.async {
                completion(access, previousStatus, currentStatus)
            }
        }
    }
    
    func addEventsToCalendar(for dateBlocks: [Date : [CourseDateBlock]], completion: @escaping (Bool) -> ()) {
        if !generateCourseCalendar() {
            completion(false)
            return
        }
        
        var events: [EKEvent] = []

        dateBlocks.forEach { item in
            let blocks = item.value
            
            if blocks.count > 1 {
                if let generatedEvent = calendarEvent(for: blocks) {
                    events.append(generatedEvent)
                }
            } else {
                if let block = blocks.first {
                    let generatedEvent = calendarEvent(for: block)
                    events.append(generatedEvent)
                }
            }
        }
        
        if events.isEmpty {
            //Ideally this shouldn't happen, but in any case if this happen so lets remove the calendar
            removeCalendar()
            completion(false)
        } else {
            events.forEach { event in addEvent(event: event) }
            do {
                try eventStore.commit()
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
    
    private func generateCourseCalendar() -> Bool {
        guard localCalendar == nil else { return true }
        do {
            let newCalendar = calendar()
            try eventStore.saveCalendar(newCalendar, commit: true)
            let courseCalendar = CourseCalendar(identifier: newCalendar.calendarIdentifier, courseID: courseID, isOn: true)
            addCalendarEntry(courseCalendar: courseCalendar, isOn: true)
            return true
        } catch {
            return false
        }
    }
    
    func removeCalendar(completion: ((Bool)->())? = nil) {
        guard let calendar = localCalendar else { return }
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            removeCalendarEntry()
            completion?(true)
        } catch {
            completion?(false)
        }
    }
    
    private func calendarEvent(for block: CourseDateBlock) -> EKEvent {
        let title = block.title + ": " + courseName
        let startDate = block.blockDate.addingTimeInterval(startDateOffsetHour * 60 * 60)
        let endDate = block.blockDate
        let notes = "\(courseName) \n \(block.title)"
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
    }
    
    private func calendarEvent(for blocks: [CourseDateBlock]) -> EKEvent? {
        guard let block = blocks.first else { return nil }
        
        let title = block.title + ": " + courseName
        let startDate = block.blockDate.addingTimeInterval(startDateOffsetHour * 60 * 60)
        let endDate = block.blockDate
        let notes = "\(courseName) \n" + blocks.compactMap { $0.title }.joined(separator: ", ")
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
    }
    
    private func generateEvent(title: String, startDate: Date, endDate: Date, notes: String) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = localCalendar
        event.notes = notes
        
        if startDate > Date() {
            let alarm = EKAlarm(absoluteDate: startDate)
            event.addAlarm(alarm)
        }
        
        return event
    }
    
    private func addEvent(event: EKEvent) {
        if !alreadyExist(event: event) {
            try? eventStore.save(event, span: .thisEvent)
        }
    }
    
    private func alreadyExist(event eventToAdd: EKEvent) -> Bool {
        guard let courseCalendar = calendarEntry else { return false }
        let calendars = eventStore.calendars(for: .event).filter { $0.calendarIdentifier == courseCalendar.identifier }
        let predicate = eventStore.predicateForEvents(withStart: eventToAdd.startDate, end: eventToAdd.endDate, calendars: calendars)
        let existingEvents = eventStore.events(matching: predicate)
        
        return existingEvents.contains { event -> Bool in
            return event.title == eventToAdd.title
                && event.startDate == eventToAdd.startDate
                && event.endDate == eventToAdd.endDate
        }
    }
    
    private func addCalendarEntry(courseCalendar: CourseCalendar, isOn: Bool) {
        var courseCalendars: [CourseCalendar] = []
        
        if let data = UserDefaults.standard.data(forKey: calendarKey),
           let decodedCourseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data) {
            courseCalendars = decodedCourseCalendars
        }
        
        if let index = courseCalendars.firstIndex(where: { $0.courseID == courseID }) {
            courseCalendars.modifyElement(atIndex: index) { element in
                element.isOn = isOn
            }
        } else {
            courseCalendars.append(courseCalendar)
        }
        
        if let data = try? PropertyListEncoder().encode(courseCalendars) {
            UserDefaults.standard.set(data, forKey: calendarKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func updateCalendarState(isOn: Bool) {
        guard let data = UserDefaults.standard.data(forKey: calendarKey),
              var courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data),
              let index = courseCalendars.firstIndex(where: { $0.courseID == courseID })
        else { return }
        
        courseCalendars.modifyElement(atIndex: index) { element in
            element.isOn = isOn
        }
        
        if let data = try? PropertyListEncoder().encode(courseCalendars) {
            UserDefaults.standard.set(data, forKey: calendarKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private func removeCalendarEntry() {
        guard let data = UserDefaults.standard.data(forKey: calendarKey),
              var courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data)
        else { return }
        
        if let index = courseCalendars.firstIndex(where: { $0.courseID == courseID }) {
            courseCalendars.remove(at: index)
        }
        
        if let data = try? PropertyListEncoder().encode(courseCalendars) {
            UserDefaults.standard.set(data, forKey: calendarKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    private var calendarEntry: CourseCalendar? {
        guard let data = UserDefaults.standard.data(forKey: calendarKey),
              let courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data)
        else { return nil }
        return courseCalendars.first(where: { $0.courseID == courseID })
    }
}
