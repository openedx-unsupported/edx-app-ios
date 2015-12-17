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

private let footerHeight = 30
public class TablePaginationController<A> : NSObject, Paginator {
    
    typealias Element = A
    
    private let tableView : UITableView
    private let paginator : AnyPaginator<A>
    private let footer : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: footerHeight))
        let activityIndicator = SpinnerView(size: .Large, color: .Primary)
        view.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { make in
            make.center.equalTo(view)
        }
        return view
    }()
    
    init<P: Paginator where P.Element == A>(paginator : P, tableView : UITableView) {
        self.tableView = tableView
        self.paginator = AnyPaginator(paginator)
        
        super.init()
        
        paginator.stream.listen(self) {[weak self] _ in
            self?.updateVisibility()
        }
        
        tableView.oex_addObserver(self, forKeyPath: "bounds") { (controller, tableView, newValue) -> Void in
            controller.viewScrolled()
        }
    }
    
    var stream : Stream<[A]> {
        return paginator.stream
    }
    
    func loadMore() {
        paginator.loadMore()
    }
    
    var hasNext: Bool {
        return paginator.hasNext
    }
    
    private func viewScrolled() {
        if !self.paginator.stream.active && tableView.scrolledNearBottom && self.paginator.hasNext {
            self.paginator.loadMore()
            self.updateVisibility()
        }
    }
    
    private func updateVisibility() {
        if self.paginator.stream.active {
            self.tableView.tableFooterView = footer
        }
        else {
            self.tableView.tableFooterView = nil
        }
    }
}
