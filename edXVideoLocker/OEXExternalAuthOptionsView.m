//
//  OEXExternalAuthOptionsView.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXExternalAuthOptionsView.h"

#import "OEXExternalAuthProvider.h"
#import "OEXExternalAuthProviderButton.h"
#import "OEXExternalRegistrationOptionsView.h"

static CGFloat OEXExternalAuthButtonAspectRatio = 3.4;

@interface OEXExternalAuthOptionsView ()

@property (strong, nonatomic) NSArray* optionButtons;

@end

@implementation OEXExternalAuthOptionsView

- (id)initWithFrame:(CGRect)frame optionButtons:(NSArray*)buttons {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.itemsPerRow = 2;
        self.optionButtons = buttons;
        for(UIButton* button in self.optionButtons) {
            [self addSubview:button];
        }
        
    }
    return self;
}

- (void)setItemsPerRow:(NSUInteger)itemsPerRow {
    _itemsPerRow = itemsPerRow;
    [self setNeedsLayout];
}

- (CGFloat)itemWidthWithHeight:(CGFloat)buttonWidth {
    return buttonWidth * OEXExternalAuthButtonAspectRatio;
}

- (CGFloat)rowHeightWithRowCount:(NSUInteger)rows {
    return (self.bounds.size.height - self.rowSpacing * (rows - 1)) / rows;
}

- (NSUInteger)itemsPerRow:(NSUInteger)rows {
    return ceil(((float)self.optionButtons.count) / rows);
}

- (NSUInteger)itemsInRow:(NSUInteger)row withMaxItemsPerRow:(NSUInteger)maxItems itemCount:(NSUInteger)itemCount {
    return (row * maxItems < itemCount) ? maxItems : (itemCount % maxItems);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat rows = 1;
    BOOL fits = false;
    
    if(self.bounds.size.width == 0) {
        return;
    }
    
    while(!fits) {
        NSUInteger itemsPerRow = [self itemsPerRow:rows];
        CGFloat rowHeight = [self rowHeightWithRowCount:rows];
        CGFloat width = [self itemWidthWithHeight:rowHeight];
        CGFloat requiredWidth = itemsPerRow * width;
        if(requiredWidth < self.bounds.size.width) {
            [self.optionButtons enumerateObjectsUsingBlock:^(UIButton* obj, NSUInteger idx, BOOL *stop) {
                NSUInteger row = idx / itemsPerRow;
                NSUInteger itemsInRow = [self itemsInRow:row withMaxItemsPerRow:itemsPerRow itemCount:self.optionButtons.count];
                NSUInteger column = idx % itemsPerRow;
                CGFloat y = rowHeight * row + self.rowSpacing * row;
                if(itemsInRow == itemsPerRow && itemsInRow != 1) {
                    // Items fit so anchor from left
                    CGFloat interItemSpacing = (self.bounds.size.width - requiredWidth) / (itemsPerRow  - 1);
                    CGFloat x = column * (width + interItemSpacing);
                    obj.frame = CGRectMake(x, y, width, rowHeight);
                }
                else {
                    // Fewer than normal (or one) items so center
                    CGFloat interItemSpacing = (self.bounds.size.width - width * itemsInRow) / (itemsInRow + 1);
                    CGFloat x = column * width + (column + 1) * interItemSpacing;
                    obj.frame = CGRectMake(x, y, width, rowHeight);
                }
            }];
            break;
        }
        rows++;
    }
}

@end
