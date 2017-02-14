//
//  UIImage_OEXHelpersTests.swift
//  edX
//
//  Created by Saeed Bashir on 1/26/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class UIImage_OEXHelpersTests : XCTestCase {
    let image = UIImage(named: "Icon-29")
    
    func testImageCropper() {
        let rect = CGRectMake(0, 0, 10, 10)
        let processedImage = image?.imageCroppedToRect(rect)
        
        XCTAssertNotEqual(processedImage?.size.width, image?.size.width)
        XCTAssertNotEqual(processedImage?.size.height, image?.size.height)
        
        XCTAssertEqual(processedImage?.size.width, rect.width)
        XCTAssertEqual(processedImage?.size.height, rect.height)
    }
    
    func testImageResizing() {
        let size = CGSizeMake(10, 10)
        let processedImage = image?.resizedTo(size)
        
        XCTAssertNotEqual(processedImage?.size.width, image?.size.width)
        XCTAssertNotEqual(processedImage?.size.height, image?.size.height)
        
        XCTAssertEqual(processedImage?.size.width, size.width)
        XCTAssertEqual(processedImage?.size.height, size.height)
    }
    
    func testDefaultOrientation() {
        
        XCTAssertTrue(image?.imageOrientation == .Up)
        let processedImage = image?.rotateUp()
        
        XCTAssertTrue(image?.imageOrientation == .Up)
        XCTAssertEqual(image?.imageOrientation, processedImage?.imageOrientation)
    }
    
    func testImageRotation() {
        // Default orientation 'Up'
        XCTAssertTrue(image?.imageOrientation == .Up)
        
        // Mirrored image
        let mirroredImage = UIImage(CGImage: (image?.CGImage)!, scale: 1.0, orientation: .RightMirrored)
        
        
        XCTAssertFalse(mirroredImage.imageOrientation == .Up)
        XCTAssertTrue(mirroredImage.imageOrientation == .RightMirrored)
        
        let processedImage = mirroredImage.rotateUp()
        
        XCTAssertTrue(processedImage.imageOrientation == .Up)
        XCTAssertEqual(image?.imageOrientation, processedImage.imageOrientation)
    }
    
}

