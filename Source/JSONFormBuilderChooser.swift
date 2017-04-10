//
//  JSONFormBuilderChooser.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private class JSONFormTableSelectionCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        tintColor = OEXStyles.shared().utilitySuccessBase()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private let cellIdentifier = "Cell"

/** Options Selector Table */
class JSONFormTableViewController<T>: UITableViewController {
    
    var dataSource: ChooserDataSource<T>?
    var instructions: String?
    var subInstructions: String?

    var doneChoosing: ((_ value:T?)->())?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func makeAndInstallHeader() {
        if let instructions = instructions {
            let headerView = UIView()
            headerView.backgroundColor = OEXStyles.shared().neutralXLight()
            
            let instructionStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBlackT())
            let headerStr = instructionStyle.attributedString(withText: instructions).mutableCopy() as! NSMutableAttributedString
            
            if let subInstructions = subInstructions {
                let style = OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
                let subStr = style.attributedString(withText: "\n" + subInstructions)
                headerStr.append(subStr)
            }
            
            let label = UILabel()
            label.attributedText = headerStr
            label.numberOfLines = 0
            
            headerView.addSubview(label)
            label.snp_makeConstraints(closure: { (make) -> Void in
                make.top.equalTo(headerView.snp_topMargin)
                make.bottom.equalTo(headerView.snp_bottomMargin)
                make.leading.equalTo(headerView.snp_leading).offset(20)
                make.trailing.equalTo(headerView.snp_trailing).inset(20)
            })
            
            let size = label.sizeThatFits(CGSize(width: 240, height: CGFloat.greatestFiniteMagnitude))
            headerView.frame = CGRect(origin: CGPoint.zero, size: size)
            
            tableView.tableHeaderView = headerView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(JSONFormTableSelectionCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        makeAndInstallHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OEXAnalytics.shared().trackScreen(withName: OEXAnalyticsScreenChooseFormValue + " " + (title ?? ""))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let index = dataSource?.selectedIndex else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: false)
    }
    
    override func willMove(toParentViewController parent: UIViewController?) {
        if parent == nil { //removing from the hierarchy
            doneChoosing?(dataSource?.selectedItem)
        }
    }
    
}

struct ChooserDatum<T> {
    let value: T
    let title: String?
    let attributedTitle: NSAttributedString?
}

class ChooserDataSource<T> : NSObject, UITableViewDataSource, UITableViewDelegate {
    let data: [ChooserDatum<T>]
    var selectedIndex: Int = -1
    var selectedItem: T? {
        return selectedIndex < data.count && selectedIndex >= 0 ? data[selectedIndex].value : nil
    }
    
    init(data: [ChooserDatum<T>]) {
        self.data = data
        super.init()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.applyStandardSeparatorInsets()
        let datum = data[indexPath.row]
        if let title = datum.attributedTitle {
            cell.textLabel?.attributedText = title
        } else {
            cell.textLabel?.text = datum.title
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        let oldIndexPath = selectedIndex
        selectedIndex = indexPath.row
        
        var rowsToRefresh = [indexPath]
        if oldIndexPath != -1 {
            rowsToRefresh.append(IndexPath(row: oldIndexPath, section: indexPath.section))
        }
        
        tableView.reloadRows(at: rowsToRefresh, with: .automatic)
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.accessoryType = indexPath.row == selectedIndex ? .checkmark : .none
    }
}
