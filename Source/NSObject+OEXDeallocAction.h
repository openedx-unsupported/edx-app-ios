//
//  NSObject+OEXDeallocAction.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OEXRemovable;

@interface NSObject (OEXDeallocAction)

/// Execute an action when the current object is deallocated. Note that at the time
/// the action is called, the original object is already nil
- (id <OEXRemovable>)oex_performActionOnDealloc:(void(^)(void))action;

@end
