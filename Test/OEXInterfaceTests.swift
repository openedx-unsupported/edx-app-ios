//
//  OEXInterfaceTests.swift
//  edX
//
//  Created by Saeed Bashir on 6/15/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
@testable import edX

class OEXInterfaceTests: XCTestCase {
    
    private var outlineURL: String!
    private var chapter1: OEXVideoPathEntry!
    private var chapter2: OEXVideoPathEntry!
    private var section1dot1: OEXVideoPathEntry!
    private var section1dot2: OEXVideoPathEntry!
    private var interface: OEXInterface!
    private var courseVideos: NSArray!
    
    override func setUp() {
        super.setUp()
        interface = OEXInterface()
        outlineURL = "http://abc/def"
        chapter1 = OEXVideoPathEntry(entryID: "chapterid1", name: "Example", category: "chapter")
        chapter2 = OEXVideoPathEntry(entryID: "chapterid2", name: "Example", category: "chapter")
        section1dot1 = OEXVideoPathEntry(entryID: "section1dot1", name: "Example", category: "sequential")
        section1dot2 = OEXVideoPathEntry(entryID: "section1dot2", name: "Example", category: "sequential")
        
        let video1 = OEXVideoSummary(videoID: UUID().uuidString, name: "Test Video", path: [chapter1, section1dot1])
        let video2 = OEXVideoSummary(videoID: UUID().uuidString, name: "Test Video", path: [chapter1, section1dot1])
        let video3 = OEXVideoSummary(videoID: UUID().uuidString, name: "Test Video", path: [chapter1, section1dot2])
        let video4 = OEXVideoSummary(videoID: UUID().uuidString, name: "Test Video", path: [chapter2, section1dot1])
        
        courseVideos = ([video1, video2, video3, video4] as NSArray).oex_map { (videoSummary) -> OEXHelperVideoDownload in
            let helperVideoDownload = OEXHelperVideoDownload()
            helperVideoDownload.summary = videoSummary as? OEXVideoSummary
            return helperVideoDownload
        } as NSArray
        
        let user = OEXUserDetails()
        user.name = "someone"
        user.userId = NSNumber(integerLiteral: 12345)
        
        interface = OEXInterface()
        interface.activate(forUser: user)
        interface.setVideos(courseVideos as! [Any], forURL: outlineURL)
    }
    
    func testVideoChapterFiltering() {
        let videos = interface.videos(forChapterID: chapter1.entryID ?? "", sectionID: nil, url: outlineURL)
        XCTAssertEqual(3, videos.count);
        XCTAssertGreaterThan(courseVideos.count, videos.count);
    }
    
    func testVideoSectionFiltering() {
        let videos = interface.videos(forChapterID: chapter1.entryID ?? "", sectionID: section1dot1.entryID, url: outlineURL)
        XCTAssertEqual(2, videos.count);
        XCTAssertGreaterThan(courseVideos.count, videos.count);
    }
    
    func testVideoChapterNamesIrrelevant() {
        XCTAssertEqual(chapter1.name, chapter2.name);
        let chapter1Videos = interface.videos(forChapterID: chapter1.entryID ?? "", sectionID: nil, url: outlineURL)
        let chapter2Videos = interface.videos(forChapterID: chapter2.entryID ?? "", sectionID: nil, url: outlineURL)
        
        let chapter1VideoIDs:NSArray = chapter1Videos.oex_map { (video) -> String in
            return (video as! OEXHelperVideoDownload).summary?.videoID ?? ""
        } as NSArray
        
        let chapter2VideoIDs:NSArray = chapter2Videos.oex_map { (video) -> String in
            return (video as! OEXHelperVideoDownload).summary?.videoID ?? ""
        } as NSArray
        
        XCTAssertNotEqual(chapter1VideoIDs, chapter2VideoIDs)
    }
    
    func testVideoSectionNamesIrrelevant() {
        XCTAssertEqual(section1dot1.name, section1dot2.name)
        let chapter1Videos = interface.videos(forChapterID: chapter1.entryID ?? "", sectionID: section1dot1.entryID, url: outlineURL)
        let chapter2Videos = interface.videos(forChapterID: chapter2.entryID ?? "", sectionID: section1dot2.entryID, url: outlineURL)
        
        let chapter1VideoIDs:NSArray = chapter1Videos.oex_map { (video) -> String in
            return (video as! OEXHelperVideoDownload).summary?.videoID ?? ""
            } as NSArray
        
        let chapter2VideoIDs:NSArray = chapter2Videos.oex_map { (video) -> String in
            return (video as! OEXHelperVideoDownload).summary?.videoID ?? ""
            } as NSArray
        
        XCTAssertNotEqual(chapter1VideoIDs, chapter2VideoIDs)
    }
}
