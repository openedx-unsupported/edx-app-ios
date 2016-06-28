//
//  LocalStorageInterface.swift
//  edX
//
//  Created by Michael Katz on 6/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@objc protocol LocalStorageInterface: class {
    func lastAccessedData(courseId: String) -> LastAccessed?
    func setLastAccessedSubsection(subsectionID: String, subsectionName: String, courseID: String, timestamp: String)
}

private enum Entities : String {
    case LastAccessed = "LastAccessed"

    func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        return NSEntityDescription.entityForName(self.rawValue, inManagedObjectContext: context)!
    }
}

@objc class CoreDataStorage : NSObject, LocalStorageInterface {

    //MARK: - Setup

    let context: NSManagedObjectContext

    override init() {
        let model = NSManagedObjectModel.mergedModelFromBundles(nil)!

        let storePath = (OEXFileUtility.userDirectory()! as NSString).stringByAppendingPathComponent("Database/edXDB.sqlite")
        let storeURL = NSURL(fileURLWithPath: storePath)
        Logger.logInfo("STORAGE", "DB path \(storeURL)")

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        } catch {
            Logger.logError("STORAGE", "unresolved error \(error)")
        }

        context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
    }

    func save() {
        do {
            try context.save()
        } catch {
            Logger.logError("STORAGE", "Could not save changes to database \(error)")
        }
    }

    //MARK: - Last Accessed

    func lastAccessedData(courseId: String) -> LastAccessed? {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = Entities.LastAccessed.entity(context)

        let query = NSPredicate(format: "course_id==%@", courseId)
        fetchRequest.predicate = query

        let result = try? context.executeFetchRequest(fetchRequest) as? [LastAccessed]

        return result?.flatMap { return $0.first }
    }

    func setLastAccessedSubsection(subsectionID: String, subsectionName: String, courseID: String, timestamp: String) {
        var last = lastAccessedData(courseID)
        if last == nil {
            last = NSEntityDescription.insertNewObjectForEntityForName(Entities.LastAccessed.rawValue, inManagedObjectContext: context) as? LastAccessed
            last?.course_id = courseID
        }
        last?.subsection_id = subsectionID
        last?.subsection_name = subsectionName
        last?.timestamp = timestamp
        save()
    }


}