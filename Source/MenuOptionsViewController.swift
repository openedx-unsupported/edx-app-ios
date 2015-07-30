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


class MenuOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let identifier = "reuseIdentifier"
    var menuWidth: CGFloat = 120.0
    var menuHeight: CGFloat = 90.0
    static let menuItemHeight: CGFloat = 30.0

    private var tableView: UITableView?
    var options: [String] = []
    var selectedOptionIndex: Int?
    weak var delegate : MenuOptionsViewControllerDelegate?
    
    private var titleTextStyle : OEXTextStyle {
        let style = OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralDark())
        return style
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: menuWidth, height: menuHeight), style: .Plain)
        tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: identifier)
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.layer.borderColor = OEXStyles.sharedStyles().neutralLight().CGColor
        tableView.layer.borderWidth = 1.0
        
        view.addSubview(tableView)
        
        self.tableView = tableView
    }

    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        let style : OEXTextStyle
        
        
        if let optionIndex = selectedOptionIndex where indexPath.row == optionIndex {
            style = titleTextStyle.withColor(OEXStyles.sharedStyles().primaryBaseColor())
        }
        else {
            style = titleTextStyle.withColor(OEXStyles.sharedStyles().neutralBlack())
        }
        cell.textLabel?.attributedText = style.attributedStringWithText(options[indexPath.row])
        
        return cell
    }
    
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if delegate?.menuOptionsController(self, canSelectOptionAtIndex:indexPath.row) ?? false {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        delegate?.menuOptionsController(self, selectedOptionAtIndex: indexPath.row)
    }
    

    // MARK: - Table view delegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }
    
}
