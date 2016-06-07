//
//  UIControl+OEXBlockActions.m
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import ObjectiveC.runtime;

#import "UIControl+OEXBlockActions.h"
#import "OEXRemovable.h"
#import "OEXAnalytics.h"

static NSString* const OEXControlActionListenersKey = @"OEXControlActionListenersKey";

@interface OEXControlActionListener : NSObject <OEXRemovable>

@property (copy, nonatomic) void (^action)(UIControl* control);
@property (copy, nonatomic) void (^removeAction)(OEXControlActionListener* listener);
@property (copy, nonatomic, nullable) NSString* eventId;

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

        if (self.eventId != nil) {
            OEXAnalyticsEvent* event = [[OEXAnalyticsEvent alloc] init];
            
            [[OEXAnalytics sharedAnalytics]trackEvent:event forComponent:nil withInfo:nil];
        }
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
    return [self oex_addAction:action forEvents:events analyticsEventId:nil];
}


- (id <OEXRemovable>)oex_addAction:(void (^)(id))action forEvents:(UIControlEvents)events analyticsEventId:(NSString* _Nullable) eventId {
    NSMutableArray* listeners = [self oex_actionListeners];
    OEXControlActionListener* listener = [[OEXControlActionListener alloc] init];
    listener.action = action;
    listener.eventId = eventId;
    
    __weak __typeof(self) weakself = self;
    listener.removeAction = ^(OEXControlActionListener* listener){
        listener.removeAction = nil;
        listener.action = nil;
        [weakself removeTarget:listener action:NULL forControlEvents:UIControlEventAllEvents];
        [[weakself oex_actionListeners] removeObject:listener];
    };
    [listeners addObject:listener];
    
    [self addTarget:listener action:@selector(actionFired:) forControlEvents:events];
    
    return listener;
}

- (void) oex_removeAllActions {
    NSMutableArray* listeners = [[self oex_actionListeners] mutableCopy];
    for (OEXControlActionListener* listener in listeners) {
        [listener remove];
    }
    [[self oex_actionListeners] removeAllObjects];
}

@end
