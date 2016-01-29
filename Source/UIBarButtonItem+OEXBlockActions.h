//
//  UIBarButtonItem+OEXBlockActions.h
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@protocol OEXRemovable;

@interface UIBarButtonItem (OEXBlocks)

/// Allows using a block as the target of a bar button item instead of a target+action
/// If you use this, setting the target and action directly is not recommended
- (id <OEXRemovable>)oex_setAction:(void (^)(void))action;

@end

NS_ASSUME_NONNULL_END
