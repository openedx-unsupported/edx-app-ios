//
//  OEXRegistrationStyles.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationStyles.h"

#import "OEXStyles.h"
#import "OEXTextStyle.h"

@implementation OEXRegistrationStyles

- (OEXTextStyle*)headingMessageTextStyle {
    OEXMutableTextStyle* style = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeXXSmall color:[[OEXStyles sharedStyles] neutralBlack]];
    style.lineBreakMode = NSLineBreakByWordWrapping;
    return style;
}

- (OEXTextStyle*)headingMessageProviderStyle {
    return [self headingMessageTextStyle].withWeight(OEXTextWeightSemiBold);
}

- (OEXTextStyle*)headingMessagePromptStyle {
    OEXTextStyle* style = [[OEXTextStyle alloc] initWithWeight:OEXTextWeightSemiBold size:OEXTextSizeSmall color:[[OEXStyles sharedStyles] neutralBlack]];
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
