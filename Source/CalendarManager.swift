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
    
    private var locallySavedCalendar: EKCalendar? {
        guard let courseCalendar = courseCalendarFromUserDefaults else {
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
        
    private func generateNewCalendar() -> EKCalendar {
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
    
    required init(courseID: String, courseName: String) {
        self.courseID = courseID
        self.courseName = courseName
    }
    
    func requestAccess(completion: @escaping (Bool, Error?, EKAuthorizationStatus) -> ()) {
        eventStore.requestAccess(to: .event) { [weak self] access, error in
            guard let weakSelf = self, access else {
                DispatchQueue.main.async {
                    completion(false, error, EKEventStore.authorizationStatus(for: .event))
                }
                return
            }
            
            if let _ = weakSelf.locallySavedCalendar {
                DispatchQueue.main.async {
                    completion(true, error, weakSelf.authorizationStatus)
                }
            } else {
                do {
                    let newCalendar = weakSelf.generateNewCalendar()
                    try weakSelf.eventStore.saveCalendar(newCalendar, commit: true)
                    let courseCalendar = CourseCalendar(identifier: newCalendar.calendarIdentifier, courseID: weakSelf.courseID, isOn: true)
                    weakSelf.saveToUserDefaults(courseCalendar: courseCalendar, isOn: true)
                    DispatchQueue.main.async {
                        completion(access, error, weakSelf.authorizationStatus)
                    }
                } catch let error {
                    print(error)
                    DispatchQueue.main.async {
                        completion(access, error, weakSelf.authorizationStatus)
                    }
                }
            }
        }
    }
    
    func addEventsToCalendar(for dateBlocksMap: [Date : [CourseDateBlock]], completion: @escaping (Bool, Error?) -> ()) {
        var events: [EKEvent] = []
        
        dateBlocksMap.forEach { item in
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
    
    func removeCalendar(completion: @escaping ()->()) {
        if let calendar = locallySavedCalendar {
            do {
                try eventStore.removeCalendar(calendar, commit: true)
                removeCourseCalendarFromUserDefaults()
                DispatchQueue.main.async {
                    completion()
                }
            } catch { }
        }
    }
    
    private func generateCalendarEvent(for block: CourseDateBlock) -> EKEvent {
        let title = block.title + ": " + courseName
        let startDate = block.blockDate.add(hours: startDateOffsetHour)
        let endDate = block.blockDate
        let notes = "\(courseName) \n \(block.title)"
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
    }
    
    private func generateCalendarEvent(for blocks: [CourseDateBlock]) -> EKEvent? {
        guard let block = blocks.first else { return nil }
        
        let title = block.title + ": " + courseName
        let startDate = block.blockDate.add(hours: startDateOffsetHour)
        let endDate = block.blockDate
        let notes = "\(courseName) \n" + blocks.compactMap { $0.title }.joined(separator: ", ")
        
        return generateEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)
    }
    
    private func generateEvent(title: String, startDate: Date, endDate: Date, notes: String) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = locallySavedCalendar
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
        guard let courseCalendar = courseCalendarFromUserDefaults else { return false }
        let calendars = eventStore.calendars(for: .event).filter { $0.calendarIdentifier == courseCalendar.identifier }
        let predicate = eventStore.predicateForEvents(withStart: eventToAdd.startDate, end: eventToAdd.endDate, calendars: calendars)
        let existingEvents = eventStore.events(matching: predicate)
        
        return existingEvents.contains { event -> Bool in
            return event.title == eventToAdd.title
                && event.startDate == eventToAdd.startDate
                && event.endDate == eventToAdd.endDate
        }
    }
}

extension CalendarManager {
    var calendarState: Bool {
        set {
            updateCalendarState()
        }
        get {
            if let courseCalendarFromUserDefaults = courseCalendarFromUserDefaults,
               let locallySavedCalendar = locallySavedCalendar {
                if courseCalendarFromUserDefaults.identifier == locallySavedCalendar.calendarIdentifier {
                    return courseCalendarFromUserDefaults.isOn
                }
            }
            return false
        }
    }
    
    private func saveToUserDefaults(courseCalendar: CourseCalendar, isOn: Bool) {
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
    
    private func updateCalendarState() {
        if let data = UserDefaults.standard.data(forKey: calendarKey),
           var courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data) {
            if let index = courseCalendars.firstIndex(where: { $0.courseID == courseID }) {
                courseCalendars.modifyElement(atIndex: index) { element in
                    element.isOn = true
                }
                
                if let data = try? PropertyListEncoder().encode(courseCalendars) {
                    UserDefaults.standard.set(data, forKey: calendarKey)
                    UserDefaults.standard.synchronize()
                }
            }
        }
    }
    
    private func removeCourseCalendarFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: calendarKey),
           var courseCalendars = try? PropertyListDecoder().decode([CourseCalendar].self, from: data) {
            
            if let index = courseCalendars.firstIndex(where: { $0.courseID == courseID }) {
                courseCalendars.remove(at: index)
            }
            
            if let data = try? PropertyListEncoder().encode(courseCalendars) {
                UserDefaults.standard.set(data, forKey: calendarKey)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    private var courseCalendarFromUserDefaults: CourseCalendar? {
        if let data = UserDefaults.standard.data(forKey: calendarKey),
           let decodedArray = try? PropertyListDecoder().decode([CourseCalendar].self, from: data) {
            return decodedArray.first(where: { $0.courseID == courseID })
        }
        
        return nil
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
