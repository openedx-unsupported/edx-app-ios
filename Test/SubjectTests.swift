//
//  SubjectTests.swift
//  edXTests
//
//  Created by Zeeshan Arif on 5/27/18.
//  Copyright © 2018 edX. All rights reserved.
//

@testable import edX

private let subjectName = "Test"
private let validImageName = "logo"
private let invalidImageName = "testinvalidimage"
private let filter = "test"
private let type = "normal"

class SubjectTests: XCTestCase {
    
    func testParser() {
        let validSubject = Subject(with: JSON(subjectRawItem(with: subjectName, imageName: validImageName, filter: filter, type: type)))
        XCTAssertNotNil(validSubject)
        XCTAssertEqual(validSubject?.name, subjectName)
        XCTAssertEqual(validSubject?.filter, filter)
        XCTAssertEqual(validSubject?.type, SubjectType(rawValue: type))
        XCTAssertNotNil(validSubject?.image)
        
        let missingImageJSON = JSON(subjectRawItem(with: subjectName, imageName: nil, filter: filter, type: type))
        let subjectWithMissingImageJSON = Subject(with: missingImageJSON)
        XCTAssertNil(subjectWithMissingImageJSON)
        
        let invalidImageJSON = JSON(subjectRawItem(with: subjectName, imageName: invalidImageName, filter: filter, type: type))
        let subjectWithInvalidImageJSON = Subject(with: invalidImageJSON)
        XCTAssertNotNil(subjectWithInvalidImageJSON)
        XCTAssertNil(subjectWithInvalidImageJSON?.image)
        
        let missingNameJSON = JSON(subjectRawItem(with: nil, imageName: validImageName, filter: filter, type: type))
        let subjectWithMissingNameJSON = Subject(with: missingNameJSON)
        XCTAssertNil(subjectWithMissingNameJSON)
        
        let missingFilterJSON = JSON(subjectRawItem(with: subjectName, imageName: validImageName, filter: nil, type: type))
        let subjectWithMissingFilterJSON = Subject(with: missingFilterJSON)
        XCTAssertNil(subjectWithMissingFilterJSON)
        
        let invalidTypeJSON = JSON(subjectRawItem(with: subjectName, imageName: validImageName, filter: filter, type: "invalidtype"))
        let subjectWithInvalidTypeJSON = Subject(with: invalidTypeJSON)
        XCTAssertNil(subjectWithInvalidTypeJSON)
    }
    
    func subjectRawItem(with name: String?, imageName: String?, filter: String?, type: String?) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        if let name = name {
            dictionary.setObject(name, forKey: "name" as NSCopying)
        }
        if let imageName = imageName {
            dictionary.setObject(imageName, forKey: "image_name" as NSCopying)
        }
        if let filter = filter {
            dictionary.setObject(filter, forKey: "filter" as NSCopying)
        }
        if let type = type {
            dictionary.setObject(type, forKey: "type" as NSCopying)
        }
        return dictionary
    }
}
