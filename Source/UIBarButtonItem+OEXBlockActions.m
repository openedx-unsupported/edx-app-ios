//
//  UIBarButtonItem+OEXBlockActions.m
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "UIBarButtonItem+OEXBlockActions.h"

#import <objc/runtime.h>
#import "OEXRemovable.h"

static NSString* const OEXBarButtonItemActionListenerKey = @"OEXBarButtonItemActionListenerKey";

@interface OEXBarButtonItemActionListener : NSObject <OEXRemovable>

@property (copy, nonatomic) void (^action)(void);
@property (copy, nonatomic) void (^removeAction)(OEXBarButtonItemActionListener* listener);

@end

@implementation OEXBarButtonItemActionListener

- (void)remove {
    if(self.removeAction != nil) {
        self.removeAction(self);
    }
}

- (void)actionFired:(UIBarButtonItem*)sender {
    if (self.action != nil) {
        self.action();
    }
}

@end

@implementation UIBarButtonItem (OEXBlockActions)

- (id <OEXRemovable>)oex_setAction:(void (^)(void))action {
    OEXBarButtonItemActionListener* listener = [[OEXBarButtonItemActionListener alloc] init];
    listener.action = action;
    
    __weak __typeof(self) weakself = self;
    listener.removeAction = ^(OEXBarButtonItemActionListener* listener){
        listener.removeAction = nil;
        listener.action = nil;
        weakself.target = nil;
        weakself.action = NULL;
        objc_setAssociatedObject(weakself, &OEXBarButtonItemActionListenerKey, nil, OBJC_ASSOCIATION_RETAIN);
    };
    
    objc_setAssociatedObject(self, &OEXBarButtonItemActionListenerKey, listener, OBJC_ASSOCIATION_RETAIN);
    
    self.target = listener;
    self.action = @selector(actionFired:);
    
    return listener;
}

@end