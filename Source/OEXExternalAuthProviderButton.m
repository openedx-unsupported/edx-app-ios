//
//  OEXExternalAuthProviderButton.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXExternalAuthProviderButton.h"

#import "edX-Swift.h"
#import "OEXExternalAuthProvider.h"
#import "OEXTextStyle.h"
#import "UIImage+OEXColors.h"

static CGFloat OEXExternalAuthProviderButtonCornerRadius = 2;
static CGFloat OEXExternalAuthButtonSeparatorInset = 4;

@interface OEXExternalAuthProviderButton ()

@property (strong, nonatomic) UIView* separator;

@end

@implementation OEXExternalAuthProviderButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self != nil) {
        self.separator = [[UIView alloc] initWithFrame:CGRectZero];
        self.separator.backgroundColor = [UIColor colorWithWhite:1 alpha:.3];
        self.imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:self.separator];
    }
    return self;
}

- (OEXTextStyle*)labelTextStyle {
    OEXMutableTextStyle* style = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightSemiBold size:OEXTextSizeSmall color:[UIColor whiteColor]];
    style.alignment = NSTextAlignmentCenter;
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
    if ([self isRightToLeft]) {
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
    CGFloat separatorX = self.bounds.size.height;
    if([self isRightToLeft]) {
        separatorX = self.bounds.size.width - separatorX;
    }
    self.separator.frame = CGRectMake(separatorX, OEXExternalAuthButtonSeparatorInset, 1, self.bounds.size.height - OEXExternalAuthButtonSeparatorInset * 2);
}

- (void)setProvider:(id<OEXExternalAuthProvider>)provider {
    _provider = provider;
    NSAttributedString* title = [[self labelTextStyle] attributedStringWithText:provider.displayName];
    [self setAttributedTitle:title forState:UIControlStateNormal];
}

@end
