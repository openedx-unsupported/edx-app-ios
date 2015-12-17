//
//  TablePaginationControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

import XCTest
@testable import edX


class TablePaginationControllerTests: XCTestCase {

    func testScrollStartsLoad() {
        let paginator = WrappedPaginator<Int> { page in
            let info = PaginationInfo(totalCount: 60, pageCount: 20)
            // Add a slight delay to make sure we get proper async behavior
            // to better match actual cases
            return Stream(value: Paginated(pagination: info, value: [1, 2, 3, 4, 5])).delay(0.1)
        }
        let tableView = UITableView(frame:CGRect(x: 0, y: 0, width: 100, height: 100))
        let paginationController = TablePaginationController(paginator: paginator, tableView: tableView)
        let dataSource = DummyTableViewDataSource<Int>()
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        
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
        let bottomIndexPath = NSIndexPath(forRow: initialCount - 1, inSection: 0)
        tableView.scrollToRowAtIndexPath(bottomIndexPath, atScrollPosition: .Bottom, animated: false)
        XCTAssertNotNil(tableView.tableFooterView) // Should be showing spinner

        // and see if we get more content
        waitForStream(paginationController.stream, fireIfAlreadyLoaded: false)
        let newCount = paginationController.stream.value?.count ?? 0
        XCTAssertGreaterThanOrEqual(newCount, initialCount)
        XCTAssertNil(tableView.tableFooterView) // Should not be showing spinner
        
    }
}
