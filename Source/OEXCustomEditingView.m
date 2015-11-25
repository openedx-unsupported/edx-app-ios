//
//  OEXCustomEditingView.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 03/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomEditingView.h"

#import "edX-Swift.h"

@implementation OEXCustomEditingView

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        // Initialization code

        [self setBackgroundColor:[UIColor colorWithRed:62.0 / 255.0 green:66.0 / 255.0 blue:71.0 / 255.0 alpha:1.0]];

        float viewWidth = SCREEN_WIDTH;
        
        // Add bottom separator image
        self.imgSeparator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewWidth, 50)];
        [self.imgSeparator setImage:[UIImage imageNamed:@"separator.png"]];
        self.imgSeparator.hidden = YES;
        [self addSubview:self.imgSeparator];

        // Add Cancel button to the view
        self.btn_Cancel = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btn_Cancel setTitle:[Strings cancel] forState:UIControlStateNormal];
        [self.btn_Cancel setFrame:CGRectMake(0, 0, (viewWidth - 2)/2 , 50)];
        self.btn_Cancel.hidden = YES;
        [self addSubview:self.btn_Cancel];

        // Add Edit button to the view
        self.btn_Edit = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btn_Edit setTitle:[Strings edit] forState:UIControlStateNormal];
        [self.btn_Edit setFrame:CGRectMake(0, 0, viewWidth, 50)];
        self.btn_Edit.hidden = NO;
        [self addSubview:self.btn_Edit];

        // Add Delete button to the view
        self.btn_Delete = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.btn_Delete setTitle:[Strings delete] forState:UIControlStateNormal];
        [self.btn_Delete setFrame:CGRectMake(viewWidth / 2, 0, (viewWidth - 2)/2, 50)];
        self.btn_Delete.hidden = YES;
        self.btn_Delete.enabled = NO;
        [self.btn_Delete setBackgroundColor:[UIColor darkGrayColor]];
        [self addSubview:self.btn_Delete];

        [self.btn_Delete setAccessibilityLabel:[Strings delete]];
        [self.btn_Delete setIsAccessibilityElement:YES];
        [self.btn_Delete accessibilityActivate];
        [self.btn_Delete setHidden:NO];

        [self.btn_Cancel setAccessibilityLabel: [Strings cancel]];
        [self.btn_Cancel setIsAccessibilityElement:YES];
        [self.btn_Cancel accessibilityActivate];
        [self.btn_Cancel setHidden:NO];

        [self.btn_Edit setAccessibilityLabel:[Strings edit]];
        [self.btn_Edit setIsAccessibilityElement:YES];
        [self.btn_Edit accessibilityActivate];
        [self.btn_Edit setHidden:NO];
    }
    return self;
}

@end
