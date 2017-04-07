//
//  PaginationControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX


class PaginationControllerTests: XCTestCase {

    func testTableScrollStartsLoad() {
        let tableView = UITableView(frame:CGRect(x: 0, y: 0, width: 100, height: 100))
        let dataSource = DummyTableViewDataSource<Int>()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        
        let paginator = WrappedPaginator<Int> { page in
            let info = PaginationInfo(totalCount: 10, pageCount: 5)
            // Add a slight delay to make sure we get proper async behavior
            // to better match actual cases
            return OEXStream(value: Paginated(pagination: info, value: [1, 2, 3, 4, 5])).delay(0.1)
        }
        let paginationController = PaginationController(paginator: paginator, tableView: tableView)
        
        paginationController.stream.listen(self) {
            dataSource.items = $0.value ?? []
            tableView.reloadData()
        }
        paginator.loadMore()
        waitForStream(paginationController.stream)
        XCTAssertFalse(paginationController.stream.active)
        
        // verify the table view has content
        let initialCount = paginationController.stream.value?.count ?? 0
        XCTAssertGreaterThanOrEqual(initialCount, 0)
        XCTAssertEqual(tableView.contentSize.height, CGFloat(initialCount) * dataSource.rowHeight)
        
        // Now scroll to the bottom
        var bottomIndexPath = IndexPath(row: initialCount - 1, section: 0)
        tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
        XCTAssertNotNil(tableView.tableFooterView) // Should be showing spinner

        // and see if we get more content
        waitForStream(paginationController.stream, fireIfAlreadyLoaded: false)
        let newCount = paginationController.stream.value?.count ?? 0
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
        
        //Scrolling to the bottom second time to confirm that results are loaded
        bottomIndexPath = IndexPath(row: newCount - 1, section: 0)
        tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
        XCTAssertNil(tableView.tableFooterView) // Should not be showing spinner
        
    }
    
    func testPaginatorSwapClearsOldPaginator() {
        let tableView = UITableView(frame:CGRect(x: 0, y: 0, width: 100, height: 100))
        let dataSource = DummyTableViewDataSource<Int>()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        
        let paginator = WrappedPaginator<Int> { page in
            let info = PaginationInfo(totalCount: 60, pageCount: 20)
            // Add a slight delay to make sure we get proper async behavior
            // to better match actual cases
            return OEXStream(value: Paginated(pagination: info, value: [1, 2, 3, 4, 5])).delay(0.1)
        }

        func connectPaginator() {
            var cleared = false
            let paginationController = PaginationController(paginator: paginator, tableView: tableView)
            paginationController.loadMore()
            
            paginationController.stream.listen(self) {
                dataSource.items = $0.value ?? []
                tableView.reloadData()
                if cleared {
                    XCTFail("Unexpected callback. Pagination controller should be deallocated")
                }
            }
            
            waitForStream(paginationController.stream, fireIfAlreadyLoaded:false)

            cleared = true
        }
        
        // Make sure the new paginator has no stale references
        autoreleasepool {
            connectPaginator()
        }
        
        // Now scroll to the bottom
        let bottomIndexPath = IndexPath(row: tableView.numberOfRows(inSection: 0) - 1, section: 0)
        tableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: false)
    }

}
