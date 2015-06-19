//
//  UIControl+OEXBlockActions.m
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <objc/runtime.h>

#import "UIControl+OEXBlockActions.h"

#import "OEXRemovable.h"

static NSString* const OEXControlActionListenersKey = @"OEXControlActionListenersKey";

@interface OEXControlActionListener : NSObject <OEXRemovable>

@property (copy, nonatomic) void (^action)(UIControl* control);
@property (copy, nonatomic) void (^removeAction)(OEXControlActionListener* listener);

@end

@implementation OEXControlActionListener

- (void)remove {
    if(self.removeAction != nil) {
        self.removeAction(self);
    }
}

- (void)actionFired:(UIControl*)sender {
    if (self.action != nil) {
        self.action(sender);
    }
}

@end

@implementation UIControl (OEXBlockActions)

- (NSMutableArray*)oex_actionListeners {
    NSMutableArray* listeners = objc_getAssociatedObject(self, &OEXControlActionListenersKey);
    if(listeners == nil) {
        listeners = [[NSMutableArray alloc] init];
        objc_setAssociatedObject(self, &OEXControlActionListenersKey, listeners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return listeners;
}

- (id <OEXRemovable>)oex_addAction:(void (^)(id))action forEvents:(UIControlEvents)events {
    NSMutableArray* listeners = [self oex_actionListeners];
    OEXControlActionListener* listener = [[OEXControlActionListener alloc] init];
    listener.action = action;
    
    __weak __typeof(self) weakself = self;
    listener.removeAction = ^(OEXControlActionListener* listener){
        listener.removeAction = nil;
        listener.action = nil;
        [weakself removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [[weakself oex_actionListeners] removeObject:listener];
    };
    [listeners addObject:listener];
    
    [self addTarget:listener action:@selector(actionFired:) forControlEvents:events];
    
    return listener;
}

- (void) oex_removeActions {
    NSMutableArray* listeners = [self oex_actionListeners];
    for (OEXControlActionListener* listener in listeners) {
        [listener remove];
    }
    [listeners removeAllObjects];
}

@end
