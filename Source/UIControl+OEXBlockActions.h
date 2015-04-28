//
//  UIControl+OEXBlockActions.h
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OEXRemovable;

@interface UIControl (OEXBlockActions)

- (id <OEXRemovable>)oex_addAction:(void (^)(id control))action forEvents:(UIControlEvents)events;

@end
