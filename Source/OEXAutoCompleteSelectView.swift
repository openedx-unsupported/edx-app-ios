//
//  OEXAutoCompleteSelectView.swift
//  edX
//
//  Created by Muhammad Umer on 15/06/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

public struct OEXAutoCompleteSelectModel {
    public var name: String
    public var value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

class OEXAutoCompleteSelectTableViewCell : UITableViewCell {
    static let identifier = "OEXAutoCompleteSelectTableViewCell"
    
    // MARK: Initialize
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = nil
        contentView.backgroundColor = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: Configure Selection
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}

typealias OEXAutoCompleteSelectModelCompletion = (OEXAutoCompleteSelectModel?) -> Swift.Void

class OEXAutoCompleteSelectViewController: UIViewController {
    // MARK: Properties
    private var selectionHandler: OEXAutoCompleteSelectModelCompletion?
    private var options = [OEXAutoCompleteSelectModel]()

    private var filteredItems: [OEXAutoCompleteSelectModel] = []
    private var selectedItem: OEXAutoCompleteSelectModel?
    
    private var searchViewHeight: CGFloat = 60
    private var tableViewRowHeight: CGFloat = 44
    private lazy var searchView: UIView = UIView()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchBar.backgroundColor = OEXStyles.shared().neutralXXLight()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.textField?.textColor = OEXStyles.shared().neutralBlackT()
        searchController.searchBar.textField?.clearButtonMode = .whileEditing
        return searchController
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = tableViewRowHeight
        tableView.separatorColor = OEXStyles.shared().neutralLight()
        tableView.bounces = true
        tableView.backgroundColor = nil
        tableView.tableFooterView = UIView()
        tableView.sectionIndexBackgroundColor = .clear
        tableView.sectionIndexTrackingBackgroundColor = .clear
        return tableView
    }()
    
    // MARK: Initialize
    required init(options: [OEXAutoCompleteSelectModel], selectedItem: OEXAutoCompleteSelectModel?, selectionHandler: @escaping OEXAutoCompleteSelectModelCompletion) {
        super.init(nibName: nil, bundle: nil)
        self.options = options
        self.selectedItem = selectedItem
        self.selectionHandler = selectionHandler
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        // http://stackoverflow.com/questions/32675001/uisearchcontroller-warning-attempting-to-load-the-view-of-a-view-controller/
        let _ = searchController.view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupViews()

        tableView.register(OEXAutoCompleteSelectTableViewCell.self, forCellReuseIdentifier: OEXAutoCompleteSelectTableViewCell.identifier)
        tableView.reloadData()
        scrollToSelectedItem()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize.height = (tableViewRowHeight * 4) + searchViewHeight
    }
    
    private func setupViews() {
        searchView.addSubview(searchController.searchBar)
        view.addSubview(searchView)
        searchView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.height.equalTo(searchViewHeight)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.searchView.snp.bottom)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        definesPresentationContext = true
    }
    
    private func itemForCell(at indexPath: IndexPath) -> OEXAutoCompleteSelectModel {
        if searchController.isActive {
            return filteredItems[indexPath.row]
        } else {
            return options[indexPath.row]
        }
    }
    
    private func indexPathOfSelectedItem() -> IndexPath? {
        guard let selectedItem = selectedItem else { return nil }
        if searchController.isActive {
            for row in 0 ..< filteredItems.count {
                if filteredItems[row].name == selectedItem.name {
                    return IndexPath(row: row, section: 0)
                }
            }
        } else {
            for row in 0 ..< options.count {
                if options[row].name == selectedItem.name {
                    return IndexPath(row: row, section: 0)
                }
            }
        }
        return nil
    }
    
    private func scrollToSelectedItem() {
        guard let selectedIndexPath = indexPathOfSelectedItem() else { return }
        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
    }
}

extension OEXAutoCompleteSelectViewController: UISearchControllerDelegate { }

// MARK: - UISearchResultsUpdating
extension OEXAutoCompleteSelectViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, searchController.isActive {
            filteredItems = []
            if searchText.count > 0 {
                filteredItems.append(contentsOf: options.filter { $0.name.hasPrefix(searchText) })
            } else {
                filteredItems = options
            }
        }
        tableView.reloadData()
        scrollToSelectedItem()
    }
}

// MARK: - UISearchBarDelegate
extension OEXAutoCompleteSelectViewController: UISearchBarDelegate { }

// MARK: - TableViewDelegate
extension OEXAutoCompleteSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemForCell(at: indexPath)
        selectedItem = item
        selectionHandler?(selectedItem)
    }
}

// MARK: - TableViewDataSource
extension OEXAutoCompleteSelectViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return filteredItems.count
        }
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemForCell(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: OEXAutoCompleteSelectTableViewCell.identifier) as! OEXAutoCompleteSelectTableViewCell
        cell.textLabel?.text = item.name
        if let selected = selectedItem, selected.name == item.name {
            cell.setSelected(true, animated: true)
        }
        return cell
    }
}

fileprivate extension UISearchBar {
    var textField: UITextField? {
        return value(forKey: "searchField") as? UITextField
    }
}
