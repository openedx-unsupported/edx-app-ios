//
//  NetworkPaginator.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 21/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

// This is deprecated. Use PaginationController + UnwrappedNetworkPaginator instead.

@available(*, deprecated, message="Use PaginationController + UnwrappedNetworkPaginator instead")

public class NetworkPaginator<A> {
    
    private let paginatedFeed : PaginatedFeed<NetworkRequest<[A]>>
    private let networkManager : NetworkManager?
    private let tableView : UITableView
    
    private let activityIndicator = SpinnerView(size: .Large, color: .Primary)
    
    public var hasMoreResults:Bool = true {
        didSet {
            if !hasMoreResults {
                self.tableView.tableFooterView = nil
            }
        }
    }
    
    init(networkManager : NetworkManager?, paginatedFeed : PaginatedFeed<NetworkRequest<[A]>>, tableView : UITableView) {
        self.paginatedFeed =  paginatedFeed
        self.networkManager = networkManager
        self.tableView = tableView
        self.loading = false
        addActivityIndicator()
        
    }
    
    func addActivityIndicator() {
        self.activityIndicator.hidesWhenStopped = true
        self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, self.tableView.bounds.size.width , 30.0))
        self.tableView.tableFooterView?.addSubview(activityIndicator)
        activityIndicator.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(tableView.tableFooterView!)
        }
    }
    
    func loadDataIfAvailable(callback : NetworkResult<[A]>? -> Void) {
        guard let nextRequest = paginatedFeed.next() where hasMoreResults else {
            loading = false
            callback(nil)
            return
        }
        loading = true
        
        networkManager?.taskForRequest(nextRequest) { [weak self] results in
            self?.loading = false
            if let items = results.data, resultsPerPage = self?.paginatedFeed.current().pageSize {
                self?.hasMoreResults = items.count == resultsPerPage
            }
            else {
                self?.hasMoreResults = false
            }
            callback(results)
        }
    }
    
    private var loading : Bool {
        didSet {
            if loading {
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
}

// To be used with a Paginated DataSource which ends up being an array in all the cases as of now.
// Note: The array is the actual Model/ViewModel
extension LoadStateViewController {
    
    func handleErrorForPaginatedArray<B>(array : [B]?, error : NSError?)
    {
        guard error != nil && (array?.isEmpty ?? true) else {
            return
        }
        self.state = LoadState.failed(error)
        
    }
}
