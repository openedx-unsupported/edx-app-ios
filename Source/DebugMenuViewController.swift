//
//  DebugMenuViewController.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private enum rows: Int {
    case AppVersion, Environment, Console, Count

    static var rowCount: Int { return Count.rawValue }

    func decorateCell(config: OEXConfig, cell: UITableViewCell) {
        switch self {
        case .AppVersion:
            let appVersion = NSBundle.mainBundle().oex_shortVersionString()
            cell.textLabel?.text = "Version: \(appVersion)"
        case .Environment:
            let environmentName = config.environmentName()!
            cell.textLabel?.text = "Environment: \(environmentName)"
        case .Console:
            cell.textLabel?.text = "Debug Console"
            cell.accessoryType = .DisclosureIndicator
        case .Count:
            fatalError("should not get here")
        }
    }
}


class DebugMenuViewController: UITableViewController {
    struct Environment {
        let config: OEXConfig
    }

    let environment: Environment

    init(environment: Environment) {
        self.environment = environment
        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug"
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.rowCount
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        let row = rows(rawValue: indexPath.row)
        row?.decorateCell(environment.config, cell: cell)

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let console = DebugLogViewController()
        navigationController?.pushViewController(console, animated: true)
    }

}