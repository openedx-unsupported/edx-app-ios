//
//  RegistrationSelectOptionViewController.swift
//  edX
//
//  Created by Muhammad Umer on 15/06/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

@objc class RegistrationSelectOptionViewModel: NSObject {
    public var name: String
    @objc public var value: String
    
    init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

class RegistrationSelectOptionViewCell : UITableViewCell {
    static let identifier = String(describing: RegistrationSelectOptionViewCell.self)
    
    // MARK: Initialize
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.accessibilityIdentifier = "RegistrationSelectOptionViewCell:content-view"
        accessibilityIdentifier = "RegistrationSelectOptionViewCell:view"
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

typealias RegistrationSelectOptionViewCompletion = (RegistrationSelectOptionViewModel?) -> Swift.Void

class RegistrationSelectOptionViewController: UIViewController {
    // MARK: Properties
    private var selectionHandler: RegistrationSelectOptionViewCompletion?
    private var options: [RegistrationSelectOptionViewModel] = []
    private var filteredOptions: [RegistrationSelectOptionViewModel] = []
    private var selectedItem: RegistrationSelectOptionViewModel?
    
    private var searchViewHeight: CGFloat = 60
    private var tableViewEstimatedRowHeight: CGFloat = 44
    private var visibleRows: CGFloat = 4
    private lazy var searchView: UIView = UIView()
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.backgroundColor = OEXStyles.shared().neutralXLight()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.textField?.textColor = OEXStyles.shared().neutralBlackT()
        searchController.searchBar.textField?.clearButtonMode = .whileEditing
        return searchController
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = tableViewEstimatedRowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorColor = OEXStyles.shared().neutralLight()
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    // MARK: Initialize
    required init(options: [RegistrationSelectOptionViewModel], selectedItem: RegistrationSelectOptionViewModel?, selectionHandler: @escaping RegistrationSelectOptionViewCompletion) {
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

        tableView.register(RegistrationSelectOptionViewCell.self, forCellReuseIdentifier: RegistrationSelectOptionViewCell.identifier)
        tableView.reloadData()
        scrollToSelectedItem()

        setAccessibilityIdentifiers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize.height = (tableView.estimatedRowHeight * visibleRows) + searchViewHeight
    }

    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "RegistrationSelectOptionViewCompletion:view"
        tableView.accessibilityIdentifier = "RegistrationSelectOptionViewCompletion:table-view"
        searchView.accessibilityIdentifier = "RegistrationSelectOptionViewCompletion:search-view"
        searchController.view.accessibilityIdentifier = "RegistrationSelectOptionViewCompletion:search-controller"
        searchController.searchBar.accessibilityIdentifier = "RegistrationSelectOptionViewCompletion:search-bar"
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
            make.height.equalTo(tableView.estimatedRowHeight * visibleRows)
        }
        
        searchController.isActive = true
        searchController.searchBar.becomeFirstResponder()
        definesPresentationContext = true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        searchController.searchBar.frame.size.width = view.frame.size.width
        searchController.searchBar.frame.size.height = searchViewHeight
    }
    
    private func itemForCell(at indexPath: IndexPath) -> RegistrationSelectOptionViewModel {
        return searchController.isActive ? filteredOptions[indexPath.row] : options[indexPath.row]
    }
    
    private func indexPathOfSelectedItem() -> IndexPath? {
        guard let selectedItem = selectedItem else { return nil }
        if searchController.isActive {
            for (key, value) in filteredOptions.enumerated() {
                if value.name == selectedItem.name {
                    return IndexPath(row: key, section: 0)
                }
            }
        } else {
            for (key, value) in options.enumerated() {
                if value.name == selectedItem.name {
                    return IndexPath(row: key, section: 0)
                }
            }
        }
        return nil
    }
    
    private func scrollToSelectedItem() {
        guard let selectedIndexPath = indexPathOfSelectedItem() else { return }
        tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .top)
    }
}

// MARK: - UISearchResultsUpdating
extension RegistrationSelectOptionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), searchController.isActive {
            filteredOptions.removeAll()
            if searchText.isEmpty {
                filteredOptions = options
            } else {
                filteredOptions.append(contentsOf: options.filter { $0.name.lowercased().hasPrefix(searchText) })
            }
        }
        tableView.reloadData()
    }
}

// MARK: - TableViewDelegate
extension RegistrationSelectOptionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = itemForCell(at: indexPath)
        selectedItem = item
        selectionHandler?(selectedItem)
    }
}

// MARK: - TableViewDataSource
extension RegistrationSelectOptionViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
       return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchController.isActive ? filteredOptions.count : options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemForCell(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: RegistrationSelectOptionViewCell.identifier) as! RegistrationSelectOptionViewCell
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
