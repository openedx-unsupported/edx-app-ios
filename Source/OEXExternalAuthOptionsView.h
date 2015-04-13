//
//  OEXExternalAuthOptionsView.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXExternalAuthOptionsView : UIView

- (id)initWithFrame:(CGRect)frame optionButtons:(NSArray*)optionButtons;

/// Defaults to 0
/// Vertical space between rows in cases where this needs to wrap
/// to multiple rows
@property (assign, nonatomic) CGFloat rowSpacing;

/// Defaults to two
@property (assign, nonatomic) NSUInteger itemsPerRow;

@end
