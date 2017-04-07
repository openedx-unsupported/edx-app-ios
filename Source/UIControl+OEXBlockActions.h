//
//  UIControl+OEXBlockActions.h
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol OEXRemovable;
@class OEXAnalyticsEvent;

@interface UIControl (OEXBlockActions)

- (id <OEXRemovable>)oex_addAction:(void (^)(NSObject* control))action forEvents:(UIControlEvents)events;
- (id <OEXRemovable>)oex_addAction:(void (^)(NSObject*))action forEvents:(UIControlEvents)events analyticsEvent:(OEXAnalyticsEvent* _Nullable) event;

- (void) oex_removeAllActions;
@end

NS_ASSUME_NONNULL_END

