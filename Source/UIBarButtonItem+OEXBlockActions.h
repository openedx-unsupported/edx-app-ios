//
//  UIBarButtonItem+OEXBlockActions.h
//  edX
//
//  Created by Akiva Leffert on 5/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OEXRemovable;

@interface UIBarButtonItem (OEXBlocks)

/// Allows using a block as the target of a bar button item instead of a target+action
/// If you use this, setting the target and action directly is not recommended
- (id <OEXRemovable>)oex_setAction:(void (^)(void))action;

@end
