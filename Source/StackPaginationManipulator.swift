//
//  StackPaginationManipulator.swift
//  edX
//
//  Created by Akiva Leffert on 4/28/16.
//  Copyright © 2016 edX. All rights reserved.
//

// Use with PaginationController to set up a paginating stack view
// Before using this, *STRONGLY* consider if you can accomplish what you're
// doing with a scroll view. Stackviews do not scale to lots of items
public class StackPaginationManipulator: ScrollingPaginationViewManipulator {

    let scrollView: UIScrollView?
    private let stackView: TZStackView

    init(stackView : TZStackView, containingScrollView scrollView: UIScrollView) {
        self.scrollView = scrollView
        self.stackView = stackView
    }

    func setFooter(footer: UIView, visible: Bool) {
        if(visible && !self.stackView.arrangedSubviews.contains(footer)) {
            self.stackView.addArrangedSubview(footer)
        }
        else if(!visible && self.stackView.arrangedSubviews.contains(footer)) {
            self.stackView.removeArrangedSubview(footer)
            footer.removeFromSuperview()
        }

    }

    var canPaginate: Bool {
        return self.stackView.window != nil
    }
}


extension PaginationController {

    convenience init<P: Paginator>(paginator: P, stackView: TZStackView, containingScrollView: UIScrollView) where P.Element == A {
        self.init(paginator: paginator, manipulator: StackPaginationManipulator(stackView: stackView, containingScrollView: containingScrollView))
    }
    
}
