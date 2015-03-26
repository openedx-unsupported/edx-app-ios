//
//  OEXRegistrationStyles.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXTextStyle;

@interface OEXRegistrationStyles : NSObject

- (OEXTextStyle*)headingMessageTextStyle;
- (OEXTextStyle*)headingMessageProviderStyle;
- (OEXTextStyle*)headingMessagePromptStyle;

- (CGFloat)formMargin;

- (CGFloat)headingPromptMarginTop;
- (CGFloat)headingPromptMarginBottom;

- (CGFloat)externalAuthButtonHeight;

@end
