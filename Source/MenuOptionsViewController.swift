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

public class MenuOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    class MenuOptionTableViewCell : UITableViewCell {
        
        static let identifier = "MenuOptionTableViewCellIdentifier"
        
        fileprivate let optionLabel = UILabel()
        
        var depth : UInt = 0 {
            didSet {
                optionLabel.snp.updateConstraints { make in
                    make.leading.equalTo(contentView).offset(indentationOffsetForDepth(itemDepth: depth))
                }
            }
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(optionLabel)
            optionLabel.snp.makeConstraints { make in
                make.leading.equalTo(contentView)
                make.centerY.equalTo(contentView)
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
    
    private let menuItemHeight: CGFloat = 30.0

    private var tableView: UITableView?
    var options: [MenuOption] = []
    var selectedOptionIndex: Int?
    weak var delegate : MenuOptionsViewControllerDelegate?
    
    private var titleTextStyle : OEXTextStyle {
        let style = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralDark())
        return style
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView?.register(MenuOptionTableViewCell.classForCoder(), forCellReuseIdentifier: MenuOptionTableViewCell.identifier)
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.layer.borderColor = OEXStyles.shared().neutralLight().cgColor
        tableView?.layer.borderWidth = 1.0
        tableView?.applyStandardSeparatorInsets()
        tableView?.cellLayoutMarginsFollowReadableWidth = false
        view.addSubview(tableView!)
        
        setConstraints()
    }
    
    private func setConstraints() {
        tableView?.snp.remakeConstraints { make in
            make.edges.equalTo(view)
            make.height.equalTo(view.snp.height).offset(-2)
        }
    }

    // MARK: - Table view data source

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.applyStandardSeparatorInsets()
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MenuOptionTableViewCell.identifier, for: indexPath as IndexPath) as! MenuOptionTableViewCell
        
        // Configure the cell...
        let style : OEXTextStyle
        let option = options[indexPath.row]
        
        cell.selectionStyle = option.depth == 0 ? .none : .default
        
        if let optionIndex = selectedOptionIndex, indexPath.row == optionIndex {
            cell.backgroundColor = OEXStyles.shared().neutralLight()
            style = titleTextStyle.withColor(OEXStyles.shared().neutralBlack())
        }
        else {
            cell.backgroundColor = OEXStyles.shared().neutralWhite()
            style = titleTextStyle
        }

        cell.depth = option.depth
        cell.optionLabel.attributedText = style.attributedString(withText: option.label)
        cell.applyStandardSeparatorInsets()
        
        if delegate?.menuOptionsController(controller: self, canSelectOptionAtIndex:indexPath.row) ?? false {
            cell.accessibilityHint = Strings.accessibilitySelectValueHint
        }
        else {
            cell.accessibilityHint = nil
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if delegate?.menuOptionsController(controller: self, canSelectOptionAtIndex:indexPath.row) ?? false {
            return indexPath
        }
        else {
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.menuOptionsController(controller: self, selectedOptionAtIndex: indexPath.row)
    }

    // MARK: - Table view delegate
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return menuItemHeight
    }
    
}
