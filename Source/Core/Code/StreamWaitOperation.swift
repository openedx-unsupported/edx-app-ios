//
//  StreamWaitOperation.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//


/// Operation that just waits for a stream to fire, extending the lifetime of the stream.
class StreamWaitOperation<A> : OEXOperation {
    fileprivate let completion : ((Result<A>) -> Void)?
    fileprivate let stream : OEXStream<A>
    fileprivate let fireIfAlreadyLoaded : Bool

    init(stream : OEXStream<A>, fireIfAlreadyLoaded : Bool, completion : ((Result<A>) -> Void)? = nil) {
        self.fireIfAlreadyLoaded = fireIfAlreadyLoaded
        self.stream = stream
        self.completion = completion
    }
    
    override func performWithDoneAction(_ doneAction: @escaping () -> Void) {
        DispatchQueue.main.async {[weak self] _ in
            if let owner = self {
                // We should just be able to do this with weak self, but the compiler crashes as of Swift 1.2
                owner.stream.listenOnce(owner, fireIfAlreadyLoaded: owner.fireIfAlreadyLoaded) {[weak owner] result in
                    if !(owner?.isCancelled ?? false) {
                        owner?.completion?(result)
                    }
                    doneAction()
                }
            }
        }
    }
}
