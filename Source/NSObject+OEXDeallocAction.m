//
//  NSObject+OEXDeallocAction.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSObject+OEXDeallocAction.h"

#import "OEXRemovable.h"

#import <objc/runtime.h>

@interface OEXDeallocActionRunner : NSObject <OEXRemovable>

@property (copy, nonatomic) void (^action)(void);
@property (copy, nonatomic) void (^removeAction)(id);

#if DEBUG
@property (copy, nonatomic) NSString* debugInfo;
#endif

@end

@implementation OEXDeallocActionRunner

- (void)dealloc {
    if(self.action != nil) {
        self.action();
    }
}

- (void)remove {
    if(self.removeAction != nil) {
        self.removeAction(self);
    }
    self.action = nil;
    self.removeAction = nil;
}

@end

@implementation NSObject (OEXDeallocActions)

- (id <OEXRemovable>)oex_performActionOnDealloc:(void(^)(void))action {
    OEXDeallocActionRunner* runner = [[OEXDeallocActionRunner alloc] init];
    runner.action = action;
    __weak __typeof(self) weakself = self;
    runner.removeAction = ^(id sender){
        objc_setAssociatedObject(weakself, (__bridge void*)sender, nil, OBJC_ASSOCIATION_RETAIN);
    };
    objc_setAssociatedObject(self, (__bridge void*)runner, runner, OBJC_ASSOCIATION_RETAIN);
    
#if DEBUG
    runner.debugInfo = self.description;
#endif
    
    return runner;
}

@end
