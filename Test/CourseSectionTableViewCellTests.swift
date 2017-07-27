//
//  CourseSectionTableViewCellTests.swift
//  edX
//
//  Created by Salman on 06/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class CourseSectionTableViewCellTests: SnapshotTestCase {
    
    let course = OEXCourse.freshCourse()
    var outline : CourseOutline!
    var router : OEXRouter!
    var environment : TestRouterEnvironment!
    let lastAccessedItem = CourseOutlineTestDataFactory.knownLastAccessedItem
    let networkManager = MockNetworkManager(baseURL: URL(string: "www.example.com")!)
    
    override func setUp() {
        super.setUp()
        
        outline = CourseOutlineTestDataFactory.freshCourseOutline(course.course_id!)
        let config = OEXConfig(dictionary: ["COURSE_VIDEOS_ENABLED": true])
        let interface = OEXInterface.shared()
        environment = TestRouterEnvironment(config: config, interface: interface)
        environment.mockCourseDataManager.querier = CourseOutlineQuerier(courseID: outline.root, interface: interface, outline: outline)
        environment.interface?.t_setCourseEnrollments([UserCourseEnrollment(course: course)])
        environment.interface?.t_setCourseVideos([course.video_outline!: OEXVideoSummaryTestDataFactory.localCourseVideos(CourseOutlineTestDataFactory.knownLocalVideoID)])
        router = OEXRouter(environment: environment)
    }
    
    func loadAndVerifyControllerWithBlockID(_ blockID : CourseBlockID, courseOutlineMode: CourseOutlineMode? = CourseOutlineMode.Full, verifier : @escaping (CourseOutlineViewController) -> ((XCTestExpectation) -> Void)?) {
        
        let blockIdOrNilIfRoot : CourseBlockID? = blockID == outline.root ? nil : blockID
        let controller = CourseOutlineViewController(environment: environment, courseID: outline.root, rootID: blockIdOrNilIfRoot, forMode: courseOutlineMode)
        let expectations = expectation(description: "course loaded")
        let updateStream = BackedStream<Void>()
        
        inScreenNavigationContext(controller) {
            DispatchQueue.main.async {
                let blockLoadedStream = controller.t_setup()
                updateStream.backWithStream(blockLoadedStream)
                updateStream.listen(controller) {[weak controller] _ in
                    updateStream.removeAllBackings()
                    if let next = controller.flatMap({ verifier($0) }) {
                        next(expectations)
                    }
                    else {
                        expectations.fulfill()
                    }
                }
            }
            waitForExpectations()
        }
    }
    
    func testForSwipeToDeleteOptionDisable() {
        loadAndVerifyControllerWithBlockID(outline.root) { (courseoutlineview) in
            let indexPath = IndexPath(row: 1, section: 0)
            let tableView = courseoutlineview.t_tableView()
            let cell = tableView.cellForRow(at: indexPath) as? CourseSectionTableViewCell
            let swipeActions = cell?.tableView(tableView, editActionsForRowAt: indexPath, for: SwipeActionsOrientation.right)
            var downloadVideos:[OEXHelperVideoDownload] = []
            let videosStream = BackedStream<[OEXHelperVideoDownload]>()
            let blockLoadedStream = cell!.t_setup()
            videosStream.backWithStream(blockLoadedStream)
            videosStream.listen(self) { downloads in
                if let videos = downloads.value {
                    downloadVideos = videos
                }
            }

            return {expectation -> Void in
                XCTAssertNil(swipeActions)
                XCTAssertFalse(cell!.t_areAllVideosDownloaded(videos: downloadVideos))
                expectation.fulfill()
            }
            
        }
    }
        
    func testForSwipeToDeleteOptionEnable() {
        loadAndVerifyControllerWithBlockID(outline.root) { (courseoutlineview) in
            let indexPath = IndexPath(row: 1, section: 0)
            let tableView = courseoutlineview.t_tableView()
            let cell = tableView.cellForRow(at: indexPath) as? CourseSectionTableViewCell
            let videosStream = BackedStream<[OEXHelperVideoDownload]>()
            let blockLoadedStream = cell!.t_setup()
            var downloadVideos:[OEXHelperVideoDownload] = []
            videosStream.backWithStream(blockLoadedStream)
            videosStream.listen(self) { downloads in
                if let downloads = downloads.value {
                    downloadVideos = downloads
                    for video in downloads {
                        video.downloadState = OEXDownloadState.complete
                    }
                }
            }
            let swipeActions = cell?.tableView(tableView, editActionsForRowAt: indexPath, for: SwipeActionsOrientation.right)
            return {expectation -> Void in
                XCTAssertNotNil(swipeActions)
                XCTAssertTrue(cell!.t_areAllVideosDownloaded(videos: downloadVideos))
                expectation.fulfill()
            }
        }
    }
    
    func testForSwipeToDeleteAction() {
        loadAndVerifyControllerWithBlockID(outline.root) { (courseoutlineview) in
            let indexPath = IndexPath(row: 1, section: 0)
            let tableView = courseoutlineview.t_tableView()
            let cell = tableView.cellForRow(at: indexPath) as? CourseSectionTableViewCell
            let videosStream = BackedStream<[OEXHelperVideoDownload]>()
            let blockLoadedStream = cell!.t_setup()
            var downloadVideos :[OEXHelperVideoDownload] = []
            videosStream.backWithStream(blockLoadedStream)
            videosStream.listen(self) { downloads in
                if let downloads = downloads.value {
                    downloadVideos = downloads
                    for video in downloads {
                        video.downloadState = OEXDownloadState.complete
                    }
                }
            }
            var swipeActions = cell?.tableView(tableView, editActionsForRowAt: indexPath, for: SwipeActionsOrientation.right)
            return {expectation -> Void in
                XCTAssertNotNil(swipeActions)
                cell?.deleteVideos(videos: downloadVideos)
                swipeActions = cell?.tableView(tableView, editActionsForRowAt: indexPath, for: SwipeActionsOrientation.right)
                XCTAssertNil(swipeActions)
                expectation.fulfill()
            }
        }
    }
    
}
