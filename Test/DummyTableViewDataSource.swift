//
//  DummyTableViewDataSource.swift
//  edX
//
//  Created by Akiva Leffert on 12/17/15.
//  Copyright © 2015 edX. All rights reserved.
//


class DummyTableViewDataSource<A> : NSObject, UITableViewDataSource, UITableViewDelegate {
    
    let rowHeight : CGFloat = 100
    
    let identifier = "CellIdentifier"
    var items : [A] = []
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath)
        return cell
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return rowHeight
    }
}