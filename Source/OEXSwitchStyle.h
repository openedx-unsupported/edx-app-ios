//
//  OEXSwitchStyle.h
//  edX
//
//  Created by Akiva Leffert on 4/24/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

// Style class for UISwitch

@interface OEXSwitchStyle : NSObject

- (id)initWithTintColor:(nullable UIColor*)tintColor onTintColor:(nullable UIColor*)onTintColor thumbTintColor:(nullable UIColor*)thumbTintColor;

/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* onTintColor;
/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* tintColor;
/// Defaults to nil, which uses the system default. See corresponding UISwitch property for details
@property (readonly, nonatomic) UIColor* thumbTintColor;

- (void)applyToSwitch:(UISwitch*)switchView;

@end

NS_ASSUME_NONNULL_END
