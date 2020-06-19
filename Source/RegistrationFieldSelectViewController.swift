//
//  RegistrationFieldSelectViewController.swift
//  edX
//
//  Created by Muhammad Umer on 15/06/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

public struct RegistrationFieldSelectViewModel {
    public var name: String
    public var value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

class RegistrationFieldSelectViewCell : UITableViewCell {
    static let identifier = String(describing: RegistrationFieldSelectViewCell.self)
    
    // MARK: Initialize
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = nil
        contentView.backgroundColor = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Configure Selection
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
    }
}

typealias RegistrationFieldSelectViewCompletion = (RegistrationFieldSelectViewModel?) -> Swift.Void

class RegistrationFieldSelectViewController: UIViewController {
    // MARK: Properties
    private var selectionHandler: RegistrationFieldSelectViewCompletion?
    private var options = [RegistrationFieldSelectViewModel]()

    private var filteredOptions: [RegistrationFieldSelectViewModel] = []
    private var selectedItem: RegistrationFieldSelectViewModel?
    
    private var searchViewHeight: CGFloat = 60
    private var tableViewRowHeight: CGFloat = 44
    private lazy var searchView: UIView = UIView()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchBar.backgroundColor = OEXStyles.shared().neutralXXLight()
        searchController.searchResultsUpdater = self
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
        tableView.backgroundColor = nil
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    // MARK: Initialize
    required init(options: [RegistrationFieldSelectViewModel], selectedItem: RegistrationFieldSelectViewModel?, selectionHandler: @escaping RegistrationFieldSelectViewCompletion) {
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
        searchController.loadViewIfNeeded()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setupViews()

        tableView.register(RegistrationFieldSelectViewCell.self, forCellReuseIdentifier: RegistrationFieldSelectViewCell.identifier)
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
        view.addSubview(tableView)

        searchView.snp.makeConstraints { make in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(searchViewHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        searchController.isActive = true
        searchController.searchBar.becomeFirstResponder()
        definesPresentationContext = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        searchController.searchBar.frame.size.width = searchView.frame.size.width
        searchController.searchBar.frame.size.height = searchView.frame.size.height
    }
    
    private func itemForCell(at indexPath: IndexPath) -> RegistrationFieldSelectViewModel {
        if searchController.isActive {
            return filteredOptions[indexPath.row]
        } else {
            return options[indexPath.row]
        }
    }
    
    private func indexPathOfSelectedItem() -> IndexPath? {
        guard let selectedItem = selectedItem else { return nil }
        if searchController.isActive {
            for row in 0 ..< filteredOptions.count {
                if filteredOptions[row].name == selectedItem.name {
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

// MARK: - UISearchResultsUpdating
extension RegistrationFieldSelectViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, searchController.isActive {
            filteredOptions = []
            if searchText.count > 0 {
                filteredOptions.append(contentsOf: options.filter { $0.name.hasPrefix(searchText) })
            } else {
                filteredOptions = options
            }
        }
        tableView.reloadData()
        scrollToSelectedItem()
    }
}

// MARK: - TableViewDelegate
extension RegistrationFieldSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemForCell(at: indexPath)
        selectedItem = item
        selectionHandler?(selectedItem)
    }
}

// MARK: - TableViewDataSource
extension RegistrationFieldSelectViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive {
            return filteredOptions.count
        }
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemForCell(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationFieldSelectViewCell.identifier) as! RegistrationFieldSelectViewCell
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
