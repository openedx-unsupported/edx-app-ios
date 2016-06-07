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

@interface UIControl (OEXBlockActions)

- (id <OEXRemovable>)oex_addAction:(void (^)(id control))action forEvents:(UIControlEvents)events;
- (id <OEXRemovable>)oex_addAction:(void (^)(id))action forEvents:(UIControlEvents)events analyticsEventId:(NSString* _Nullable) eventId;

- (void) oex_removeAllActions;
@end

NS_ASSUME_NONNULL_END

