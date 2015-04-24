//
//  OEXSwitchStyle.m
//  edX
//
//  Created by Akiva Leffert on 4/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSwitchStyle.h"

@interface OEXSwitchStyle ()

@property (strong, nonatomic) UIColor* onTintColor;
@property (strong, nonatomic) UIColor* tintColor;
@property (strong, nonatomic) UIColor* thumbTintColor;

@end

@implementation OEXSwitchStyle

- (id)initWithTintColor:(UIColor*)tintColor onTintColor:(UIColor*)onTintColor thumbTintColor:(UIColor*)thumbTintColor {
    self = [super init];
    if(self != nil) {
        self.tintColor = tintColor;
        self.onTintColor = onTintColor;
        self.thumbTintColor = thumbTintColor;
    }
    return self;
}

- (void)applyToSwitch:(UISwitch*)switchView {
    switchView.tintColor = self.tintColor;
    switchView.onTintColor = self.onTintColor;
    switchView.thumbTintColor = self.thumbTintColor;
}

@end
