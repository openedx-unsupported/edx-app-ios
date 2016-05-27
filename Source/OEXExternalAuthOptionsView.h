//
//  OEXExternalAuthOptionsView.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol OEXExternalAuthProvider;

@interface OEXExternalAuthOptionsView : UIView

- (id)initWithFrame:(CGRect)frame providers:(NSArray<id<OEXExternalAuthProvider>>*)providers tapAction:(void(^)(id<OEXExternalAuthProvider>))tapAction;

/// Vertical space between rows in cases where this needs to wrap
/// to multiple rows
@property (assign, nonatomic) CGFloat rowSpacing;

/// Defaults to two
@property (assign, nonatomic) NSUInteger itemsPerRow;

@end

NS_ASSUME_NONNULL_END
