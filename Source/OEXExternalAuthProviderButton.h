//
//  OEXExternalAuthenticationProviderButton.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

#import "OEXExternalAuthProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface OEXExternalAuthProviderButton : UIButton

/// Adds the color as a backgroundImage. Unlike setting the backgroundColor, this provides
/// a pressed state
- (void)useBackgroundImageOfColor:(UIColor*)color;

@property (strong, nonatomic) id <OEXExternalAuthProvider> provider;

@end

NS_ASSUME_NONNULL_END
