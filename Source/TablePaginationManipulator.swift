//
//  TablePaginationManipulator.swift
//  edX
//
//  Created by Akiva Leffert on 4/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

class TablePaginationManipulator : ScrollingPaginationViewManipulator {
    private let tableView : UITableView

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    func setFooter(footer: UIView, visible: Bool) {
        if visible {
            self.tableView.tableFooterView = footer
        }
        else {
            self.tableView.tableFooterView = nil
        }
    }

    var scrollView: UIScrollView? {
        return tableView
    }

    var canPaginate: Bool {
        return true
    }
}

extension PaginationController {

    convenience init<P: Paginator>(paginator: P, tableView: UITableView) where P.Element == A{
        self.init(paginator: paginator, manipulator: TablePaginationManipulator(tableView: tableView))
    }
    
}
