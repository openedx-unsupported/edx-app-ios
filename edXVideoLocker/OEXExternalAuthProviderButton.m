//
//  OEXExternalAuthProviderButton.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXExternalAuthProviderButton.h"

#import "OEXTextStyle.h"
#import "UIImage+OEXColors.h"

static CGFloat OEXExternalAuthProviderButtonCornerRadius = 2;
static CGFloat OEXExternalAuthButtonSeparatorInset = 4;

@interface OEXExternalAuthProviderButton ()

@property (strong, nonatomic) UIView* separator;

@end

@implementation OEXExternalAuthProviderButton

// This seems like it should be unnecessary
// but when I didn't have it, I got a method not found crash.
// Maybe a compiler bug?
@synthesize provider = _provider;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.separator = [[UIView alloc] initWithFrame:CGRectZero];
        self.separator.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
        self.imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.separator];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [[self labelTextStyle] applyToLabel:self.titleLabel];
    }
    return self;
}

- (OEXTextStyle*)labelTextStyle {
    OEXMutableTextStyle* style = [OEXMutableTextStyle style];
    style.size = 14;
    style.color = [UIColor whiteColor];
    style.font = OEXTextFontThemeSansBold;
    return style;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGFloat height = contentRect.size.height;
    CGFloat width = contentRect.size.width - height;
    CGFloat x = height;
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        x = 0;
    }
    CGRect result = UIEdgeInsetsInsetRect(CGRectMake(x, 0, width, height), self.titleEdgeInsets);
    return result;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGFloat height = contentRect.size.height;
    CGFloat x = 0;
    if ([UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft) {
        x = self.bounds.size.width - height;
    }
    CGRect result = UIEdgeInsetsInsetRect(CGRectMake(x, 0, height, height), self.imageEdgeInsets);
    return result;
}

- (void)useBackgroundImageOfColor:(UIColor *)color {
    UIImage* backgroundImage = [UIImage oex_imageWithColor:color];
    [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = OEXExternalAuthProviderButtonCornerRadius;
    self.layer.masksToBounds = YES;
    self.separator.frame = CGRectMake(self.frame.size.height, OEXExternalAuthButtonSeparatorInset, 1, self.frame.size.height - OEXExternalAuthButtonSeparatorInset * 2);
}


@end
