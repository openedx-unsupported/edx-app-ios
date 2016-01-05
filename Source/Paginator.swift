//
//  Paginator.swift
//  edX
//
//  Created by Akiva Leffert on 12/16/15.
//  Copyright © 2015 edX. All rights reserved.
//

protocol Paginator {
    typealias Element
    // Accumulation of all the objects loaded so far
    var stream : Stream<[Element]> { get }
    var hasNext : Bool { get }
    func loadMore()
}

// Since Swift doesn't support generic protocols, we need a way to wrap
// the associated type from Paginator into a generic parameter.
// This bridges the two. This is slightly awkward so 
// TODO: Revisit when Swift supports generic protocols
class AnyPaginator<A> : Paginator {
    typealias Element = A
    let stream : Stream<[Element]>
    private var _hasNext: () -> Bool
    let _loadMore: () -> Void
    
    init<P: Paginator where P.Element == A>(_ paginator : P) {
        self.stream = paginator.stream
        self._loadMore = paginator.loadMore
        self._hasNext = { paginator.hasNext }
    }
    
    var hasNext : Bool {
        return _hasNext()
    }
    
    func loadMore() {
        self._loadMore()
    }
}

class WrappedPaginator<A> : NSObject, Paginator {
    typealias Element = A
    
    private var itemStream = BackedStream<Paginated<[A]>>()
    private var generator : Int -> Stream<Paginated<[A]>>
    private var currentPage : Int = PaginationDefaults.startPage
    
    init(generator : Int -> Stream<Paginated<[A]>>) {
        self.generator = generator
    }
    
    convenience init(networkManager : NetworkManager, requestGenerator : Int -> NetworkRequest<Paginated<[A]>>) {
        self.init {page in
            let request = requestGenerator(page)
            return networkManager.streamForRequest(request)
        }
    }
    
    private(set) lazy var stream : Stream<[A]> = {
        accumulate(self.itemStream.map { $0.value } )
    }()
    
    var hasNext: Bool {
        return currentPage == PaginationDefaults.startPage || (stream.value?.count ?? 0) != itemStream.value?.pagination.totalCount
    }
    
    func loadMore() {
        if !itemStream.active {
            let stream = generator(currentPage)
            itemStream.backWithStream(stream)
            stream.listenOnce(self) {[weak self] in
                if $0.isSuccess {
                    self?.currentPage += 1
                }
            }
        }
    }
}

// We previously did not return an explicit pagination body in our endpoints.
// As such, this is a paginator that guesses whether it's at the end of the stream.
// DO NOT ADD MORE USES OF THIS
// Instead, update the server endpoint to use a standard pagination container
// and use WrappedPaginator.
class UnwrappedNetworkPaginator<A> : NSObject, Paginator {
    typealias Element = A
    private var itemStream = BackedStream<[A]>()
    private var generator : Int -> NetworkRequest<[A]>
    private var lastRequest: NetworkRequest<[A]>?
    private let networkManager : NetworkManager
    private var currentPage : Int = PaginationDefaults.startPage
    
    init(networkManager : NetworkManager, generator : Int -> NetworkRequest<[A]>) {
        self.networkManager = networkManager
        self.generator = generator
    }
    
    private(set) lazy var stream : Stream<[A]> = {
        accumulate(self.itemStream)
    }()
    
    var hasNext : Bool {
        guard let lastRequest = lastRequest else { return true }
        guard let pageSize = lastRequest.pageSize else { return true }
        guard let lastItems = itemStream.value else { return true }
        // This is just an approximation since we don't have count information
        // If we returned a number other than the page size, we must be out of pages
        return lastItems.count == pageSize
    }
    
    func loadMore() {
        if !itemStream.active {
            let request = generator(currentPage)
            lastRequest = request
            
            let stream = networkManager.streamForRequest(request)
            itemStream.backWithStream(stream)
            stream.listenOnce(self) {[weak self] in
                if $0.isSuccess {
                    self?.currentPage += 1
                }
            }
        }
    }
}