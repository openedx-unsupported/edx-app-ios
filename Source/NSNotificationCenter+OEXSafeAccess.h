//
//  NSNotificationCenter+OEXSafeAccess.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/30/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol OEXRemovable;

@interface NSNotificationCenter (OEXSafeAccess)

/// Safer way of dealing with NSNotification registration
/// The notification listener will be removed automatically when observer is dealloced
/// Additionally, you can use the removable argument to the listener to preemptively remove the
/// listener making it easy to do one off notification observations
- (id <OEXRemovable>)oex_addObserver:(id)observer notification:(NSString*)name action:(void(^)(NSNotification* notification, id observer, id <OEXRemovable> removable))action;

@end

NS_ASSUME_NONNULL_END
