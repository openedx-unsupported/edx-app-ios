//
//  OEXRegistrationFieldPassword.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldPasswordView.h"

@implementation OEXRegistrationFieldPasswordView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.textInputView.secureTextEntry = YES;
    }
    return self;
}

@end
