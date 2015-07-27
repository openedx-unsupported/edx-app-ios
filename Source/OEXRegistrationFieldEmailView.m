//
//  OEXRegistrationFieldEmailView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 14/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldEmailView.h"

@interface OEXRegistrationFieldEmailView ()
@end

@implementation OEXRegistrationFieldEmailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:self.bounds];
    if(self) {
        self.textInputView.keyboardType = UIKeyboardTypeEmailAddress;
    }
    return self;
}

@end
