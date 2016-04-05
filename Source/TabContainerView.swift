//
//  TabContainerView.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

// Simple tab view with a segmented control at the top
class TabContainerView : UIView {

    struct Item {
        let name : String
        let view : UIView
        let identifier : String
    }

    private let control = UISegmentedControl()

    private let stackView = TZStackView()
    private var activeTabBodyView : UIView? = nil

    private var currentIdentifier : String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.insertArrangedSubview(control, atIndex: 0)
        stackView.axis = .Vertical
        stackView.alignment = .Fill
        stackView.spacing = StandardVerticalMargin

        addSubview(stackView)
        stackView.snp_makeConstraints {make in
            make.leading.equalTo(self.snp_leadingMargin)
            make.trailing.equalTo(self.snp_trailingMargin)
            make.top.equalTo(self.snp_topMargin)
            make.bottom.equalTo(self.snp_bottomMargin)
        }

        let selectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralBlackT())
        let unselectedAttributes = OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
        control.setTitleTextAttributes(selectedAttributes.attributes, forState: .Selected)
        control.setTitleTextAttributes(unselectedAttributes.attributes, forState: .Normal)
        control.tintColor = OEXStyles.sharedStyles().primaryXLightColor()
        control.oex_addAction({[weak self] control in
            let index = (control as! UISegmentedControl).selectedSegmentIndex
            self?.showTabAtIndex(index)
            }, forEvents: .ValueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var items : [Item] = [] {
        didSet {
            control.removeAllSegments()

            for (index, item) in items.enumerate() {
                control.insertSegmentWithTitle(item.name, atIndex: control.numberOfSegments, animated: false)
                if item.identifier == currentIdentifier {
                    showTabAtIndex(index)
                }
            }
            if control.selectedSegmentIndex == UISegmentedControlNoSegment && items.count > 0 {
                showTabAtIndex(0)
            }
            else {
                currentIdentifier = nil
            }

            if items.count < 2 {
                control.hidden = true
            }
        }
    }

    private func showTabAtIndex(index: Int) {
        guard index != UISegmentedControlNoSegment else {
            return
        }

        activeTabBodyView?.removeFromSuperview()

        let item = items[index]
        control.selectedSegmentIndex = index
        currentIdentifier = item.identifier
        stackView.addArrangedSubview(item.view)
        activeTabBodyView = item.view
    }

    private func indexOfItemWithIdentifier(identifier : String) -> Int? {
        return items.firstIndexMatching {$0.identifier == identifier }
    }

    func showTabWithIdentifier(identifier : String) {
        if let index = indexOfItemWithIdentifier(identifier) {
            showTabAtIndex(index)
        }
    }
}

// Only used for testing
extension TabContainerView {
    func t_isShowingViewForItem(item : Item) -> Bool {
        let viewsMatch = stackView.arrangedSubviews == [control, item.view]
        let indexMatches = indexOfItemWithIdentifier(item.identifier) == control.selectedSegmentIndex
        let identifierMatches = currentIdentifier == item.identifier
        return viewsMatch && indexMatches && identifierMatches
    }
}