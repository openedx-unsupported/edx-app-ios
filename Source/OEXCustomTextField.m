//
//  OEXCustomTextField.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 09/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomTextField.h"
#import "OEXStyles.h"

@implementation OEXCustomTextField

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        // set custom font

        switch(self.tag)
        {
            case 101:   //Username.
                self.font = [[OEXStyles sharedStyles] sansSerifOfSize:self.font.pointSize];
                break;

            case 102:   //password
                self.font = [[OEXStyles sharedStyles] sansSerifOfSize:self.font.pointSize];
                break;

            default:
                break;
        }
    }
    return self;
}

@end
