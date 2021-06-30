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
    var identifier: String
    let courseID: String
    var isOn: Bool
    var modalPresented: Bool
}

class CalendarManager: NSObject {
    
    private let courseName: String
    private let courseID: String
    
    private let eventStore = EKEventStore()
    private let iCloudCalendar = "icloud"
    private let alertOffset = -1
    private let calendarKey = "CalendarEntries"
    
    private var localCalendar: EKCalendar? {
        if authorizationStatus != .authorized { return nil }
        
        var calendars = eventStore.calendars(for: .event).filter { $0.title == calendarName }
        
        if calendars.isEmpty {
            return nil
        } else {
            let calendar = calendars.removeLast()
            // calendars.removeLast() pop the element from array and after that,
            // following is run on remaing members of array to remove them
            // calendar app, if they had been added.
            calendars.forEach { try? eventStore.removeCalendar($0, commit: true) }
            
            return calendar
        }
    }
    
    private let calendarColor = OEXStyles.shared().primaryBaseColor()
    
    private var calendarSource: EKSource? {
        eventStore.refreshSourcesIfNecessary()
        
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
    
    var syncOn: Bool {
        set {
            updateCalendarState(isOn: newValue)
        }
        get {
            if let calendarEntry = calendarEntry,
               let localCalendar = localCalendar {
                if calendarEntry.identifier == localCalendar.calendarIdentifier {
                    return calendarEntry.isOn
                }
            } else {
                if let localCalendar = localCalendar {
                    let courseCalendar = CourseCalendar(identifier: localCalendar.calendarIdentifier, courseID: courseID, isOn: true, modalPresented: false)
                    addOrUpdateCalendarEntry(courseCalendar: courseCalendar)
                    return true
                }
            }
            return false
        }
    }
    
    var isModalPresented: Bool {
        set {
            setModalPresented(presented: newValue)
        }
        get {
            return getModalPresented()
        }
    }
    
    required init(courseID: String, courseName: String) {
        self.courseID = courseID
        self.courseName = courseName
    }
    
    func requestAccess(completion: @escaping (Bool, EKAuthorizationStatus, EKAuthorizationStatus) -> ()) {
        let previousStatus = EKEventStore.authorizationStatus(for: .event)
        eventStore.requestAccess(to: .event) { [weak self] access, _ in
            self?.eventStore.reset()
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
        
        let events = generateEvents(for: dateBlocks)
        
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
    
    func checkIfEventsShouldBeShifted(for dateBlocks: [Date : [CourseDateBlock]]) -> Bool {
        guard let _ = calendarEntry else { return true }
        
        let events = generateEvents(for: dateBlocks)
        let allEvents = events.allSatisfy { alreadyExist(event: $0) }
        
        return !allEvents
    }
    
    private func generateEvents(for dateBlocks: [Date : [CourseDateBlock]]) -> [EKEvent] {
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
        
        return events
    }
    
    private func generateCourseCalendar() -> Bool {
        guard localCalendar == nil else { return true }
        do {
            let newCalendar = calendar()
            try eventStore.saveCalendar(newCalendar, commit: true)
            
            let courseCalendar: CourseCalendar
            
            if var calendarEntry = calendarEntry {
                calendarEntry.identifier = newCalendar.calendarIdentifier
                courseCalendar = calendarEntry
            } else {
                courseCalendar = CourseCalendar(identifier: newCalendar.calendarIdentifier, courseID: courseID, isOn: true, modalPresented: false)
            }
            
            addOrUpdateCalendarEntry(courseCalendar: courseCalendar)
            
            return true
        } catch {
            return false
        }
    }
    
    func removeCalendar(completion: ((Bool)->())? = nil) {
        guard let calendar = localCalendar else { return }
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            updateSyncSwitchStatus(isOn: false)
            completion?(true)
        } catch {
            completion?(false)
        }
    }
    
    private func calendarEvent(for block: CourseDateBlock) -> EKEvent {
        let title = block.title + ": " + courseName
        // startDate is the start date and time for the event,
        // it is also being used as first alert for the event
        let startDate = block.blockDate.add(.hour, value: alertOffset)
        let secondAlert = startDate.add(.day, value: alertOffset)
        let endDate = block.blockDate
        let notes = "\(courseName) \n \(block.title)"
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, secondAlert: secondAlert, notes: notes)
    }
    
    private func calendarEvent(for blocks: [CourseDateBlock]) -> EKEvent? {
        guard let block = blocks.first else { return nil }
        
        let title = block.title + ": " + courseName
        // startDate is the start date and time for the event,
        // it is also being used as first alert for the event
        let startDate = block.blockDate.add(.hour, value: alertOffset)
        let secondAlert = startDate.add(.day, value: alertOffset)
        let endDate = block.blockDate
        let notes = "\(courseName) \n" + blocks.compactMap { $0.title }.joined(separator: ", ")
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, secondAlert: secondAlert, notes: notes)
    }
    
    private func generateEvent(title: String, startDate: Date, endDate: Date, secondAlert: Date, notes: String) -> EKEvent {
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
        
        if secondAlert > Date() {
            let alarm = EKAlarm(absoluteDate: secondAlert)
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
    
    private func addOrUpdateCalendarEntry(courseCalendar: CourseCalendar) {
        var calenders: [CourseCalendar] = []
        
        if let decodedCalendars = courseCalendars() {
            calenders = decodedCalendars
        }
        
        if let index = calenders.firstIndex(where: { $0.courseID == courseID }) {
            calenders.modifyElement(atIndex: index) { element in
                element = courseCalendar
            }
        } else {
            calenders.append(courseCalendar)
        }
        
        saveCalendarEntry(calendars: calenders)
    }
    
    private func updateCalendarState(isOn: Bool) {
        guard var calendars = courseCalendars(),
              let index = calendars.firstIndex(where: { $0.courseID == courseID })
        else { return }
        
        calendars.modifyElement(atIndex: index) { element in
            element.isOn = isOn
        }
        
        saveCalendarEntry(calendars: calendars)
    }
    
    private func setModalPresented(presented: Bool) {
        guard var calendars = courseCalendars(),
              let index = calendars.firstIndex(where: { $0.courseID == courseID })
        else { return }
        
        calendars.modifyElement(atIndex: index) { element in
            element.modalPresented = presented
        }
        
        saveCalendarEntry(calendars: calendars)
    }
    
    private func getModalPresented() -> Bool {
        guard let calendars = courseCalendars(),
              let calendar = calendars.first(where: { $0.courseID == courseID })
        else { return false }
        
        return calendar.modalPresented
    }
    
    private func removeCalendarEntry() {
        guard var calendars = courseCalendars() else { return }
        
        if let index = calendars.firstIndex(where: { $0.courseID == courseID }) {
            calendars.remove(at: index)
        }
        
        saveCalendarEntry(calendars: calendars)
    }
    
    private func updateSyncSwitchStatus(isOn: Bool) {
        guard var calendars = courseCalendars() else { return }
        
        if let index = calendars.firstIndex(where: { $0.courseID == courseID }) {
            calendars.modifyElement(atIndex: index) { element in
                element.isOn = isOn
            }
        }
        
        saveCalendarEntry(calendars: calendars)
    }
    
    private var calendarEntry: CourseCalendar? {
        guard let calendars = courseCalendars() else { return nil }
        return calendars.first(where: { $0.courseID == courseID })
    }
    
    private func courseCalendars() ->  [CourseCalendar]? {
        guard let data = UserDefaults.standard.data(forKey: calendarKey),
              let courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data)
        else { return nil }
        
        return courseCalendars
    }
    
    private func saveCalendarEntry(calendars: [CourseCalendar]) {
        guard let data = try? PropertyListEncoder().encode(calendars) else { return }
        
        UserDefaults.standard.set(data, forKey: calendarKey)
        UserDefaults.standard.synchronize()
    }
}

fileprivate extension Date {
    func add(_ unit: Calendar.Component, value: Int) -> Date {
        return Calendar.current.date(byAdding: unit, value: value, to: self) ?? self
    }
}
