//
//  OEXRemovable.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// This protocol should be avoided in Swift code. See plain "Removable"
@protocol OEXRemovable <NSObject>

- (void)remove;

@end

@interface OEXBlockRemovable : NSObject <OEXRemovable>

- (id)initWithRemovalAction:(nullable void (^)(void))action;

@end

NS_ASSUME_NONNULL_END
