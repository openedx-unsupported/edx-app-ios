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
        super.init(style: .Default, reuseIdentifier: reuseIdentifier)
        tintColor = OEXStyles.sharedStyles().utilitySuccessBase()
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
    
    var doneChoosing: ((value:T?)->())?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    private func makeAndInstallHeader() {
        if let instructions = instructions {
            let headerView = UIView()
            headerView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
            
            let instructionStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralBlackT())
            let headerStr = instructionStyle.attributedStringWithText(instructions).mutableCopy() as! NSMutableAttributedString
            
            if let subInstructions = subInstructions {
                let style = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
                let subStr = style.attributedStringWithText("\n" + subInstructions)
                headerStr.appendAttributedString(subStr)
            }
            
            let label = UILabel()
            label.attributedText = headerStr
            label.numberOfLines = 0
            
            headerView.addSubview(label)
            label.snp_makeConstraints(closure: { (make) -> Void in
                make.top.equalTo(headerView.snp_topMargin)
                make.bottom.equalTo(headerView.snp_bottomMargin)
                make.leading.equalTo(headerView.snp_leadingMargin)
                make.trailing.equalTo(headerView.snp_trailingMargin)
            })
            
            let size = label.sizeThatFits(CGSizeMake(240, CGFloat.max))
            headerView.frame = CGRect(origin: CGPointZero, size: size)
            
            tableView.tableHeaderView = headerView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.registerClass(JSONFormTableSelectionCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.dataSource = dataSource
        tableView.delegate = dataSource
        makeAndInstallHeader()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let index = dataSource?.selectedIndex else { return }
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), atScrollPosition: .Middle, animated: false)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil { //removing from the hierarchy
            doneChoosing?(value: dataSource?.selectedItem)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
        let datum = data[indexPath.row]
        if let title = datum.attributedTitle {
            cell.textLabel?.attributedText = title
        } else {
            cell.textLabel?.text = datum.title
        }
        return cell
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let oldIndexPath = selectedIndex
        selectedIndex = indexPath.row
        
        var rowsToRefresh = [indexPath]
        if oldIndexPath != -1 {
            rowsToRefresh.append(NSIndexPath(forRow: oldIndexPath, inSection: indexPath.section))
        }
        
        tableView.reloadRowsAtIndexPaths(rowsToRefresh, withRowAnimation: .Automatic)
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.accessoryType = indexPath.row == selectedIndex ? .Checkmark : .None
    }
}