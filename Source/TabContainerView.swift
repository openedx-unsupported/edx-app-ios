//
//  TabContainerView.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation


struct TabItem {
    let name : String
    let view : UIView
    let identifier : String
}

// Simple tab view with a segmented control at the top
class TabContainerView : UIView {

    fileprivate let control = UISegmentedControl()

    fileprivate let stackView = TZStackView()
    private var activeTabBodyView : UIView? = nil

    fileprivate var currentIdentifier : String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.insertArrangedSubview(control, atIndex: 0)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = StandardVerticalMargin

        addSubview(stackView)
        stackView.snp_makeConstraints {make in
            make.leading.equalTo(self.snp_leadingMargin)
            make.trailing.equalTo(self.snp_trailingMargin)
            make.top.equalTo(self.snp_topMargin)
            make.bottom.equalTo(self.snp_bottomMargin)
        }

        control.oex_addAction({[weak self] control in
            let index = (control as! UISegmentedControl).selectedSegmentIndex
            self?.showTabAtIndex(index: index)
            }, for: .valueChanged)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var items : [TabItem] = [] {
        didSet {
            control.removeAllSegments()

            for (index, item) in items.enumerated() {
                control.insertSegment(withTitle: item.name, at: control.numberOfSegments, animated: false)
                if item.identifier == currentIdentifier {
                    showTabAtIndex(index: index)
                }
            }
            if control.selectedSegmentIndex == UISegmentedControlNoSegment && items.count > 0 {
                showTabAtIndex(index: 0)
            }
            else {
                currentIdentifier = nil
            }
            control.isHidden = items.count < 2
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

    fileprivate func indexOfItem(withIdentifier identifier : String) -> Int? {
        return items.firstIndexMatching {$0.identifier == identifier }
    }

    func showTab(withIdentifier identifier : String) {
        if let index = indexOfItem(withIdentifier: identifier) {
            showTabAtIndex(index: index)
        }
    }
}

// Only used for testing
extension TabContainerView {
    func t_isShowingView(forItem item : TabItem) -> Bool {
        let viewsMatch = stackView.arrangedSubviews == [control, item.view]
        let indexMatches = indexOfItem(withIdentifier: item.identifier) == control.selectedSegmentIndex
        let identifierMatches = currentIdentifier == item.identifier
        return viewsMatch && indexMatches && identifierMatches
    }
}
