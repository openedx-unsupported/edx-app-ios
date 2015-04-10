//
//  NSNotificationCenter+OEXSafeAccess.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "NSNotificationCenter+OEXSafeAccess.h"

#import "OEXRemovable.h"
#import "NSObject+OEXDeallocAction.h"

@interface OEXNotificationListener : NSObject <OEXRemovable>

@property (strong, nonatomic) id observer;
@property (weak, nonatomic) id owner;
@property (copy, nonatomic) void (^action)(NSNotification* notification, id observer, id <OEXRemovable> removable);

@end

@implementation OEXNotificationListener

- (void)notificationFired:(NSNotification*)notification {
    if(self.action != nil) {
        self.action(notification, self.owner, self);
    }
}

- (void)remove {
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer name:nil object:nil];
    self.observer = nil;
    self.owner = nil;
    self.action = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer name:nil object:nil];
}

@end

@implementation NSNotificationCenter (OEXSafeAccess)

- (id <OEXRemovable>)oex_addObserver:(id)observer notification:(NSString*)name action:(void (^)(NSNotification *, id, id<OEXRemovable>))action {
    
    OEXNotificationListener* listener = [[OEXNotificationListener alloc] init];
    listener.owner = observer;
    listener.action = action;
    
    __weak __typeof(listener) weakListener = listener;
    listener.observer = [[NSNotificationCenter defaultCenter] addObserverForName:name object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        [weakListener notificationFired:note];
    }];
    [observer oex_performActionOnDealloc: ^{
        [listener remove];
    }];
    return listener;
}

@end
