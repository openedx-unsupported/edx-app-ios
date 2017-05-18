//
//  WhatsNewObjectTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/12/17.
//  Copyright © 2017 edX. All rights reserved.
//

@testable import edX

private let imageName = "test_screen_1.png"
private let title = "Test Title"
private let message = "Test Message"

class WhatsNewObjectTests: XCTestCase {
    
    func testParser() {
        let validJson = whatsNewRawItem(imageName: imageName, title: title, message: message)
        let whatsnewItem = WhatsNew(json: JSON(validJson))
        XCTAssertNotNil(whatsnewItem)
        XCTAssertNotNil(whatsnewItem?.image)
        XCTAssertNotNil(whatsnewItem?.title)
        XCTAssertNotNil(whatsnewItem?.message)
        
        XCTAssertEqual(whatsnewItem?.title, title)
        XCTAssertEqual(whatsnewItem?.message, message)
        
        let missingImageName = whatsNewRawItem(imageName: nil, title: title, message: message)
        let whatsnewItem1  = WhatsNew(json: JSON(missingImageName))
        XCTAssertNil(whatsnewItem1)
        
        let missingTitle = whatsNewRawItem(imageName: imageName, title: nil, message: message)
        let whatsnewItem2  = WhatsNew(json: JSON(missingTitle))
        XCTAssertNil(whatsnewItem2)
        
        let missingMessage = whatsNewRawItem(imageName: imageName, title: title, message: nil)
        let whatsnewItem3  = WhatsNew(json: JSON(missingMessage))
        XCTAssertNil(whatsnewItem3)
        
        let invalidImageName = whatsNewRawItem(imageName: "test_screen_100.png", title: title, message: message)
        let whatsnewItem4  = WhatsNew(json: JSON(invalidImageName))
        XCTAssertNil(whatsnewItem4)
    }
    
    func whatsNewRawItem(imageName: String?, title: String?, message: String?) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        if let imageName = imageName {
            dictionary.setObject(imageName, forKey: "image" as NSCopying)
        }
        if let title = title {
            dictionary.setObject(title, forKey: "title" as NSCopying)
        }
        if let message = message {
            dictionary.setObject(message, forKey: "message" as NSCopying)
        }
        
        return dictionary
    }
}
