//
//  OEXRegistrationFieldPassword.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldPasswordView.h"

@implementation OEXRegistrationFieldPasswordView

-(instancetype)init{
    self=[super init];
    if(self){
        inputView.secureTextEntry=YES;
    }
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
