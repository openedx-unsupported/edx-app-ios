//
//  OEXRegistrationStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationStyles.h"

#import "OEXTextStyle.h"

@implementation OEXRegistrationStyles

- (OEXTextStyle*)headingMessageTextStyle {
    OEXMutableTextStyle* style = [OEXMutableTextStyle styleWithThemeSansAtSize:11.];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    return style;
}

- (OEXTextStyle*)headingMessageProviderStyle {
    return [self headingMessageTextStyle].asBold;
}

- (OEXTextStyle*)headingMessagePromptStyle {
    OEXMutableTextStyle* style = [OEXMutableTextStyle styleWithThemeSansAtSize:14.];
    style.font = OEXTextFontThemeSansBold;
    style.color = [UIColor lightGrayColor];
    return style;
}

- (CGFloat)formMargin {
    return 20;
}

- (CGFloat)headingPromptMarginTop {
    return 16;
}

- (CGFloat)headingPromptMarginBottom {
    return 8;
}

- (CGFloat)externalAuthButtonHeight {
    return 40;
}

@end
