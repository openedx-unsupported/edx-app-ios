//
//  NetworkPaginator.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 21/08/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


//public protocol NetworkPaginatorDelegate {
//    typealias A
//    func didFetchItems() -> [A]
//}

public class NetworkPaginator<A> {
    
    private let paginatedNetworkRequest : PaginatedNetworkRequest<A>
    private let networkManager : NetworkManager
    
    private var hasMoreResults = true
    
    init(paginatedNetworkRequest : PaginatedNetworkRequest<A>, networkManager : NetworkManager) {
        self.paginatedNetworkRequest = paginatedNetworkRequest
        self.networkManager = networkManager
    }

    
    func loadDataIfAvailable(callback : [A]? -> Void) {
        if (!hasMoreResults) { callback(nil) }
        networkManager.taskForRequest(paginatedNetworkRequest.requestForNextPage()) { [weak self] results in
            if let items = results.data {
                self?.hasMoreResults = items.count != 0 || items.count != self?.paginatedNetworkRequest.pageSize
                callback(items)
            }
        }
    }
}
