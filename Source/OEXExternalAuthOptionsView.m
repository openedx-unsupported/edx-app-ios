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
#import "OEXFacebookAuthProvider.h"
#import "OEXGoogleAuthProvider.h"

static CGFloat OEXExternalAuthButtonAspectRatio = 3.3;
static CGFloat rowHeight = 30;

@interface OEXExternalAuthOptionsView ()

@property (strong, nonatomic) NSArray* optionButtons;

@end

@implementation OEXExternalAuthOptionsView

- (id)initWithFrame:(CGRect)frame providers:(nonnull NSArray *)providers accessibilityLabel:(NSString*)accessibilityLabel tapAction:(void(^)(id<OEXExternalAuthProvider>))tapAction {
    
    self = [super initWithFrame:frame];
    if(self != nil) {
        
        self.rowSpacing = [[OEXStyles sharedStyles] standardVerticalMargin] + 5;
        self.optionButtons = [providers oex_map:^id(id <OEXExternalAuthProvider> provider) {
            self.itemsPerRow += 1;
            UIButton* button = [provider freshAuthButton];
            if ([provider isKindOfClass:[OEXFacebookAuthProvider class]]) {
                button.accessibilityIdentifier = @"ExternalAuthOptionsView:facebook-button";
            }
            else if ([provider isKindOfClass:[OEXGoogleAuthProvider class]]) {
                button.accessibilityIdentifier = @"ExternalAuthOptionsView:google-button";
            }
            button.accessibilityLabel = [NSString stringWithFormat:@"%@ %@",accessibilityLabel,button.titleLabel.text];
            [button oex_addAction:^(id  _Nonnull control) {
                tapAction(provider);
            } forEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            // We made adjustsFontSizeToFitWidth as true to fix the dynamic type text
            [button.titleLabel setAdjustsFontSizeToFitWidth:true];
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
        CGFloat width = [self itemWidthWithHeight:rowHeight];
        float itemInRow = self.bounds.size.width / width  ;
        NSUInteger rows = ceil(((float)self.optionButtons.count) /(float) itemInRow);
        return CGSizeMake(self.bounds.size.width, rows * rowHeight + self.rowSpacing * (rows - 1));
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
