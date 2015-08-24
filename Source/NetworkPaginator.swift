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
    
    private let paginatedNetworkRequest : PaginatedNetworkRequest<[A]>
    private let networkManager : NetworkManager

    public var resultsClosure : ([A] -> Void)?
    
    private var items : BackedStream<A> = BackedStream()
    
//    public var delegate : NetworkPaginatorDelegate<Out>?
    
    init(paginatedNetworkRequest : PaginatedNetworkRequest<[A]>, networkManager : NetworkManager) {
        self.paginatedNetworkRequest = paginatedNetworkRequest
        self.networkManager = networkManager
        loadInitialData()
    }
    
    func loadInitialData() {
        networkManager.taskForRequest(paginatedNetworkRequest.initialNetworkRequest) { results in
            if let items = results.data[0] {
                resultsClosure(items)
            }
            
        }
        
//        let stream = networkManager.streamForRequest(paginatedNetworkRequest.initialNetworkRequest, persistResponse: false, autoCancel: false)
//        items.backWithStream(stream)
//        items.listen(owner: self, success: { [weak self] results in
//            if let closure = self?.resultsClosure {
//                closure(results)
//            }
//        }, failure: nil)
        
        
        
        
    }
}
