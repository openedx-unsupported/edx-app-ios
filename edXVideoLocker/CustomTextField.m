//
//  CustomTextField.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "CustomTextField.h"

@implementation CustomTextField

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // set custom font
        
        switch (self.tag)
        {
            case 101:   //Username.
                self.font = [UIFont fontWithName:@"OpenSans" size:self.font.pointSize];
                break;
                
            case 102:   //password
                self.font = [UIFont fontWithName:@"OpenSans" size:self.font.pointSize];
                break;
                
            default:
                break;
        }

    }
    return self;
}


@end
