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
        let rect = CGRect(x: 0, y: 0, width: 10, height: 10)
        let processedImage = image?.imageCropped(toRect: rect)
        
        XCTAssertNotEqual(processedImage?.size.width, image?.size.width)
        XCTAssertNotEqual(processedImage?.size.height, image?.size.height)
        
        XCTAssertEqual(processedImage?.size.width, rect.width)
        XCTAssertEqual(processedImage?.size.height, rect.height)
    }
    
    func testImageResizing() {
        let size = CGSize(width: 10, height: 10)
        let processedImage = image?.resizedTo(size: size)
        
        XCTAssertNotEqual(processedImage?.size.width, image?.size.width)
        XCTAssertNotEqual(processedImage?.size.height, image?.size.height)
        
        XCTAssertEqual(processedImage?.size.width, size.width)
        XCTAssertEqual(processedImage?.size.height, size.height)
    }
    
    func testDefaultOrientation() {
        
        XCTAssertTrue(image?.imageOrientation == .up)
        let processedImage = image?.rotateUp()
        
        XCTAssertTrue(image?.imageOrientation == .up)
        XCTAssertEqual(image?.imageOrientation, processedImage?.imageOrientation)
    }
    
    func testImageRotation() {
        // Default orientation 'Up'
        XCTAssertTrue(image?.imageOrientation == .up)
        
        // Mirrored image
        let mirroredImage = UIImage(cgImage: (image?.cgImage)!, scale: 1.0, orientation: .rightMirrored)
        
        
        XCTAssertFalse(mirroredImage.imageOrientation == .up)
        XCTAssertTrue(mirroredImage.imageOrientation == .rightMirrored)
        
        let processedImage = mirroredImage.rotateUp()
        
        XCTAssertTrue(processedImage.imageOrientation == .up)
        XCTAssertEqual(image?.imageOrientation, processedImage.imageOrientation)
    }
    
}

