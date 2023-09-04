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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}
