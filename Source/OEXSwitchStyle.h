//
//  OEXSwitchStyle.h
//  edX
//
//  Created by Akiva Leffert on 4/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

// Style class for UISwitch

@interface OEXSwitchStyle : NSObject

- (id)initWithTintColor:(UIColor*)tintColor onTintColor:(UIColor*)onTintColor thumbTintColor:(UIColor*)thumbTintColor;

/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* onTintColor;
/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* tintColor;
/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* thumbTintColor;

- (void)applyToSwitch:(UISwitch*)switchView;

@end
