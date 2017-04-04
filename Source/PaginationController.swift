//
//  TablePaginationController.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//


extension UIScrollView {
    var scrolledNearBottom : Bool {
        // Rough guess for near bottom: One screen's worth of content away or less
        return self.bounds.maxY + self.bounds.height >= self.contentSize.height
    }
}


protocol ScrollingPaginationViewManipulator {
    func setFooter(footer: UIView, visible: Bool)
    var scrollView: UIScrollView? { get }
    var canPaginate: Bool { get }
}

private let footerHeight = 30

public class PaginationController<A> : NSObject, Paginator {
    typealias Element = A

    private let paginator : AnyPaginator<A>
    private let viewManipulator: ScrollingPaginationViewManipulator

    private let footer : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: footerHeight))
        let activityIndicator = SpinnerView(size: .Large, color: .Primary)
        view.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { make in
            make.center.equalTo(view)
        }
        return view
    }()

    init<P: Paginator>(paginator: P, manipulator: ScrollingPaginationViewManipulator) where P.Element == A {
        self.paginator = AnyPaginator(paginator)
        self.viewManipulator = manipulator
        super.init()
        manipulator.setFooter(footer: self.footer, visible: false)

        manipulator.scrollView?.oex_addObserver(observer: self, forKeyPath: "bounds") { (controller, tableView, newValue) -> Void in
            controller.viewScrolled()
        }
    }

    var stream : OEXStream<[A]> {
        return paginator.stream
    }

    func loadMore() {
        paginator.loadMore()
    }

    var hasNext: Bool {
        return paginator.hasNext
    }

    private func updateVisibility() {
        viewManipulator.setFooter(footer: self.footer, visible: self.paginator.stream.active)
    }

    private func viewScrolled() {
        if !self.paginator.stream.active && (viewManipulator.scrollView?.scrolledNearBottom ?? false) && viewManipulator.canPaginate && self.paginator.hasNext {
            self.paginator.loadMore()
            self.updateVisibility()
        }
        else if !self.paginator.hasNext && (viewManipulator.scrollView?.scrolledNearBottom ?? false){
            self.updateVisibility()
        }
    }

}

