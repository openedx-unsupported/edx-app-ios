//
//  AdditionalTabBarViewController.swift
//  edX
//
//  Created by Salman on 31/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

protocol AdditionalTableViewCellItem {
    var identifier: String { get }
    var action:(() -> Void) { get }
    var height: CGFloat { get }
    
    func decorateCell(cell: UITableViewCell)
}

struct AdditionalCellItem : AdditionalTableViewCellItem {
    let identifier = AdditionalTableViewCell.identifier
    let height:CGFloat = 85.0
    
    let title: String
    let detail: String
    let icon : Icon
    let action:(() -> Void)
    
    
    typealias CellType = AdditionalTableViewCell
    func decorateCell(cell: UITableViewCell) {
        guard let dashboardCell = cell as? AdditionalTableViewCell else { return }
        dashboardCell.useItem(item: self)
    }
}

class AdditionalTabBarViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    private let tableView: UITableView = UITableView()
    fileprivate var cellItems: [AdditionalTableViewCellItem] = []
    private let environment: Environment
    
    init(environment: Environment, cellItems:[TabBarItem]) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        prepareTableViewData(items: cellItems)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        view.backgroundColor = environment.styles.standardBackgroundColor()
        title = Strings.resourses
        // Set up tableView
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    
        // Register tableViewCell
        tableView.register(AdditionalTableViewCell.self, forCellReuseIdentifier: AdditionalTableViewCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
    
    private func prepareTableViewData(items:[TabBarItem]) {
        cellItems = []
        for item in items {
            let standardCourseItem = AdditionalCellItem(title: item.title, detail: item.detailText, icon: item.icon) {
                self.environment.router?.pushViewController(controller: item.viewController, fromController: self)
            }
            cellItems.append(standardCourseItem)
        }
    }
    
    // MARK: - TableView Data and Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellItems[indexPath.row].height
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dashboardItem = cellItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: dashboardItem.identifier, for: indexPath as IndexPath)
        dashboardItem.decorateCell(cell: cell)
        tableView.isScrollEnabled = tableView.contentSize.height > tableView.frame.size.height
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dashboardItem = cellItems[indexPath.row]
        dashboardItem.action()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
}
