//
//  WhatsNewDataModel.swift
//  edX
//
//  Created by Saeed Bashir on 5/2/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

private let FileName = "whats_new"

class WhatsNewDataModel {
    
    private var json: JSON = JSON(NSNull())
    private(set) var fields: [WhatsNew]? = []
    private let environment: RouterEnvironment?
    private(set) var versionString: String
    
    init(fileName name: String? = FileName, environment: RouterEnvironment?, version: String) {
        self.environment = environment
        self.versionString = version
        
        do {
            json = try loadJSON(jsonFile: name ?? FileName)
        } catch {
            json = JSON(NSNull())
            //Assert to crash on development
            assert(false, "Unable to load whats_new.json")
            return
        }
        
        populateFields()
    }
    
    private func populateFields() {
        guard let objects = whatsNewForCurrentVersion() else {
            //Assert to crash on development
            assert(false, "Could not find any messages for current version in whats_new.json")
            return
        }
        
        for object in objects {
            if var item = WhatsNew(json: object) {
                if item.message.contains("platform_name") {
                    let message = item.message.replacingOccurrences(of: "platform_name", with: environment?.config.platformName() ?? "")
                    item.message = message
                }
                fields?.append(item)
            }
        }
        
        if var lastItem = fields?.last {
            lastItem.isLast = true
            let count = fields?.count ?? 0
            fields?[count - 1] = lastItem
        }
    }
    
    private func loadJSON(jsonFile: String) throws -> JSON {
        var json: JSON
        if let filePath = Bundle.main.path(forResource: jsonFile, ofType: "json") {
            if let data = NSData(contentsOfFile: filePath) {
                var error: NSError?
                json = JSON(data: data as Data, error: &error)
                if error != nil { throw error! }
            } else {
                json = JSON(NSNull())
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
            }
        }  else {
            json = JSON(NSNull())
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        }
        return json
    }
    
    private func whatsNewForCurrentVersion()-> [JSON]? {
        guard let objects = json.array else {
            //Assert to crash on development
            assert(false, "Could not find any whatsNew object in whats_new.json")
            return nil
        }
        
        for object in objects {
            if let versionString = object["version"].string {
                let version = Version(version: versionString)
                let appVersion = Version(version: self.versionString)
                if appVersion.isMajorMinorVersionsSame(otherVersion: version) {
                    return object["messages"].array
                }
            }
        }
        
        return nil
    }
    
    func nextItem(currentItem: WhatsNew?)-> WhatsNew? {
        if hasNext(item: currentItem) {
            return fields?[itemIndex(item: currentItem) + 1]
        }
        return nil
    }
    
    func prevItem(currentItem: WhatsNew?)-> WhatsNew? {
        if hasPrev(item: currentItem) {
            return fields?[itemIndex(item: currentItem) - 1]
        }
        return nil
    }
    
    private func hasNext(item: WhatsNew?)-> Bool {
        guard let item = item else { return false }
        let index = fields?.index(of: item)
        return index != (fields?.count ?? 0) - 1
    }
    
    private func hasPrev(item: WhatsNew?)-> Bool {
        guard let item = item else { return false }
        return fields?.index(of: item) != 0
    }
    
    func itemIndex(item: WhatsNew?)-> Int {
        guard let item = item else { return 0 }
        return fields?.index(of: item) ?? -1
    }
}
