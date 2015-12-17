//
//  DetachedStreamOperation.swift
//  edX
//
//  Created by Akiva Leffert on 6/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


/// Operation that just waits for a stream to fire, extending the lifetime of the stream.
class StreamWaitOperation<A> : Operation {
    private let completion : (Result<A> -> Void)?
    private let stream : Stream<A>

    init(stream : Stream<A>, completion : (Result<A> -> Void)? = nil) {
        self.stream = stream
        self.completion = completion
    }

    override func performWithDoneAction(doneAction: () -> Void) {
        dispatch_async(dispatch_get_main_queue()) {[weak self] _ in
            if let owner = self {
                // We should just be able to do this with weak self, but the compiler crashes as of Swift 1.2
                owner.stream.listen(owner, fireIfAlreadyLoaded: true) {[weak owner] result in
                    if !(owner?.cancelled ?? false) {
                        owner?.completion?(result)
                    }
                    doneAction()
                }
            }
        }
    }
}

