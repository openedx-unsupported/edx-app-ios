//
//  MenuOptionsViewController.swift
//  edX
//
//  Created by Tang, Jeff on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol MenuOptionsViewControllerDelegate : class {
    func menuOptionsController(controller : MenuOptionsViewController, selectedOptionAtIndex index: Int)
    func menuOptionsController(controller : MenuOptionsViewController, canSelectOptionAtIndex index: Int) -> Bool
}

//TODO: Remove this (duplicate) when swift compiler recognizes this extension from DiscussionTopicsCell.swift
extension UITableViewCell {
    
    private func indentationOffsetForDepth(itemDepth depth : UInt) -> CGFloat {
        return CGFloat(depth + 1) * OEXStyles.sharedStyles().standardHorizontalMargin()
    }
}

public class MenuOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    class MenuOptionTableViewCell : UITableViewCell {
        
        static let identifier = "MenuOptionTableViewCellIdentifier"
        
        private let optionLabel = UILabel()
        
        var depth : UInt = 0 {
            didSet {
                optionLabel.snp_updateConstraints { (make) -> Void in
                    make.leading.equalTo(contentView).offset(self.indentationOffsetForDepth(itemDepth: depth))
                }
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(optionLabel)
            optionLabel.snp_makeConstraints { (make) -> Void in
                make.centerY.equalTo(contentView)
                make.leading.equalTo(contentView)
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    public struct MenuOption {
        let depth : UInt
        let label : String
    }
    
    var menuWidth: CGFloat = 120.0
    var menuHeight: CGFloat = 90.0
    static let menuItemHeight: CGFloat = 30.0

    private var tableView: UITableView?
    var options: [MenuOption] = []
    var selectedOptionIndex: Int?
    weak var delegate : MenuOptionsViewControllerDelegate?
    
    private var titleTextStyle : OEXTextStyle {
        let style = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
        return style
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: menuWidth, height: menuHeight), style: .Plain)
        tableView.registerClass(MenuOptionTableViewCell.classForCoder(), forCellReuseIdentifier: MenuOptionTableViewCell.identifier)
        tableView.separatorStyle = .SingleLine
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.layer.borderColor = OEXStyles.sharedStyles().neutralLight().CGColor
        tableView.layer.borderWidth = 1.0
        
        view.addSubview(tableView)
        
        self.tableView = tableView
    }

    // MARK: - Table view data source

    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MenuOptionTableViewCell.identifier, forIndexPath: indexPath) as! MenuOptionTableViewCell
        
        // Configure the cell...
        let style : OEXTextStyle
        let option = options[indexPath.row]
        
        cell.selectionStyle = option.depth == 0 ? .None : .Default
        
        if let optionIndex = selectedOptionIndex where indexPath.row == optionIndex {
            cell.backgroundColor = OEXStyles.sharedStyles().neutralLight()
            style = titleTextStyle.withColor(OEXStyles.sharedStyles().neutralBlack())
        }
        else {
            cell.backgroundColor = OEXStyles.sharedStyles().neutralWhite()
            style = titleTextStyle
        }

        cell.depth = option.depth
        cell.optionLabel.attributedText = style.attributedStringWithText(option.label)
        cell.applyStandardSeparatorInsets()
        return cell
    }
    
    public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if delegate?.menuOptionsController(self, canSelectOptionAtIndex:indexPath.row) ?? false {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.menuOptionsController(self, selectedOptionAtIndex: indexPath.row)
    }

    // MARK: - Table view delegate
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }
    
}
