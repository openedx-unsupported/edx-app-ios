//
//  OEXExternalAuthOptionsView.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "edX-Swift.h"

#import "OEXExternalAuthOptionsView.h"

#import "NSArray+OEXFunctional.h"
#import "UIControl+OEXBlockActions.h"
#import "OEXExternalAuthProvider.h"
#import "OEXExternalRegistrationOptionsView.h"

static CGFloat OEXExternalAuthButtonAspectRatio = 3.4;

@interface OEXExternalAuthOptionsView ()

@property (strong, nonatomic) NSArray* optionButtons;

@end

@implementation OEXExternalAuthOptionsView

- (id)initWithFrame:(CGRect)frame providers:(nonnull NSArray *)providers tapAction:(void(^)(id<OEXExternalAuthProvider>))tapAction {
    self = [super initWithFrame:frame];
    if(self != nil) {
        
        self.rowSpacing = [[OEXStyles sharedStyles] standardVerticalMargin];
        self.optionButtons = [providers oex_map:^id(id <OEXExternalAuthProvider> provider) {
            self.itemsPerRow += 1;
            UIButton* button = [provider freshAuthButton];
            button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",[Strings registrationRegisterPrompt],button.titleLabel.text];
            [button oex_addAction:^(id  _Nonnull control) {
                tapAction(provider);
            } forEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            return button;
        }];
        
        if (self.itemsPerRow <= 1 )
            self.itemsPerRow = 1;
    }

    return self;

}

- (CGSize)intrinsicContentSize {
    if(self.optionButtons.count == 0) {
        return CGSizeMake(UIViewNoIntrinsicMetric, 0);
    }
    else {
        CGFloat height = 30;
        NSUInteger rows = (self.optionButtons.count + self.optionButtons.count - 1) / self.itemsPerRow;


        return CGSizeMake(UIViewNoIntrinsicMetric, rows * height + self.rowSpacing * (rows - 1));
    }
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
    return ((row + 1)* maxItems < itemCount) ? maxItems : (itemCount % maxItems ?: itemCount);
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

                CGFloat interItemSpacing = (self.bounds.size.width - width * itemsInRow) / (itemsInRow + 1);
                CGFloat x = column * width + (column + 1) * interItemSpacing;
                obj.frame = CGRectMake(x, y, width, rowHeight);
            }];
            break;
        }
        rows++;
    }
}

@end
