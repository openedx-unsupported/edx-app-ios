//
//  Subject.swift
//  edX
//
//  Created by Zeeshan Arif on 5/22/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

enum SubjectType: String {
    case popular = "popular"
    case normal = "normal"
}

public class Subject {
    
    let name: String
    let image: UIImage
    let filter: String
    let type: SubjectType
    
    init?(with json: JSON) {
        guard let name = json[Keys.name].string,
            let imageName = json[Keys.imageName].string,
            let filter = json[Keys.filter].string,
            let type = json[Keys.type].string,
            let subjectType = SubjectType(rawValue: type) else {
            return nil
        }
        
        image = UIImage(named: imageName) ?? #imageLiteral(resourceName: "logo.png")
        self.name = name
        self.filter = filter
        self.type = subjectType
    }
    
    private enum Keys {
        static let name = "name"
        static let imageName = "image_name"
        static let filter = "filter"
        static let type = "type"
    }
}

private let FileName = "subjects"
public class SubjectDataModel {
    
    private(set) var subjects: [Subject] = []
    var popularSubjects: [Subject] {
        return subjects.filter { $0.type == .popular }
    }
    
    init(fileName name: String? = FileName) {
        do {
            if let subjectsJSON = try loadJSON(jsonFile: name ?? FileName).array {
                for json in subjectsJSON {
                    if let subject = Subject(with: json) {
                        subjects.append(subject)
                    }
                }
            }
        } catch {
            //Assert to crash on development
            assert(false, "Unable to load \(String(describing: name)).json")
            return
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
}
