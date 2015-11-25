
//
//  OEXCustomNavigationView.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomNavigationView.h"

#import "edX-Swift.h"

#define MOVE_X 20.0

@implementation OEXCustomNavigationView

- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        // Initialization code

        _isShifted = NO;

        // Add Back button tot he view
        self.btn_Back = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.btn_Back setAccessibilityLabel:@"btnNavigation"];
        [self.btn_Back setIsAccessibilityElement:YES];
        [self.btn_Back accessibilityActivate];
        [self.btn_Back setHidden:NO];

        [self.btn_Back setFrame:CGRectMake(0, 20, 60, 40)];
        [self addSubview:self.btn_Back];

        // Add title label to the view
        self.lbl_TitleView = [[UILabel alloc] initWithFrame:CGRectMake(50, 31, 220, 20)];
        [self.lbl_TitleView setAccessibilityLabel:@"txtHeader"];
        [self.lbl_TitleView setIsAccessibilityElement:YES];
        [self.lbl_TitleView accessibilityActivate];
        [self.lbl_TitleView setHidden:NO];
        self.lbl_TitleView.textAlignment = NSTextAlignmentCenter;
        self.lbl_TitleView.backgroundColor = [UIColor clearColor];
        self.lbl_TitleView.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0];
        self.lbl_TitleView.textColor = [UIColor colorWithRed:69.0 / 255.0 green:73.0 / 255.0 blue:81.0 / 255.0 alpha:1.0];
        [self addSubview:self.lbl_TitleView];

        // Add OFFLINE label to the view
        self.lbl_Offline = [[UILabel alloc] initWithFrame:CGRectMake(232, 31, 71, 20)];
        self.lbl_Offline.textAlignment = NSTextAlignmentRight;
        self.lbl_Offline.text = [[Strings offlineMode] uppercaseStringWithLocale:[NSLocale currentLocale]];
        self.lbl_Offline.backgroundColor = [UIColor clearColor];
        self.lbl_Offline.font = [UIFont fontWithName:@"OpenSans" size:9.0];
        self.lbl_Offline.textColor = [UIColor colorWithRed:179.0 / 255.0 green:43.0 / 255.0 blue:101.0 / 255.0 alpha:1.0];
        [self addSubview:self.lbl_Offline];

        // Add bottom separator image
        self.imgSeparator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 62, SCREEN_WIDTH, 2)];
        [self.imgSeparator setImage:[UIImage imageNamed:@"separator.png"]];
        [self addSubview:self.imgSeparator];

        //#b32b65
        self.view_Offline = [[UIView alloc] initWithFrame:CGRectMake(0, 62, SCREEN_WIDTH, 2)];
        [self.view_Offline setBackgroundColor:[UIColor colorWithRed:179.0 / 255.0 green:43.0 / 255.0 blue:101.0 / 255.0 alpha:1.0]];
        self.view_Offline.hidden = YES;
        [self addSubview:self.view_Offline];

        self.btn_Back.exclusiveTouch = YES;
        self.exclusiveTouch = YES;
    }
    return self;
}

// MOB - 591
- (void)adjustPositionIfOnline:(BOOL)online {
    if(online) {
        [self.lbl_TitleView setFrame:CGRectMake(50, 31, 220, 20)];
    }
    else {
        [self.lbl_TitleView setFrame:CGRectMake(50, 31, 170, 20)];
    }
}

- (void)adjustPositionOfComponentsWithEditingMode:(BOOL)isEditingMode isOnline:(BOOL)online {
    // MOB - 591

    CGFloat width = 0;

    if(isEditingMode) {
        if(online) {
            width = 200;
        }
        else {
            width = 175;
        }

        self.lbl_TitleView.frame = CGRectMake(self.lbl_TitleView.frame.origin.x, self.lbl_TitleView.frame.origin.y, width, self.lbl_TitleView.frame.size.height);

        if(!_isShifted) {
            _isShifted = YES;
            self.lbl_TitleView.frame = CGRectMake(self.lbl_TitleView.frame.origin.x - MOVE_X, self.lbl_TitleView.frame.origin.y, width, self.lbl_TitleView.frame.size.height);

            self.lbl_Offline.frame = CGRectMake(self.lbl_Offline.frame.origin.x - MOVE_X - 10, self.lbl_Offline.frame.origin.y, self.lbl_Offline.frame.size.width, self.lbl_Offline.frame.size.height);
        }
    }
    else {
        if(online) {
            width = 220;
        }
        else {
            width = 180;
        }

        self.lbl_TitleView.frame = CGRectMake(self.lbl_TitleView.frame.origin.x, self.lbl_TitleView.frame.origin.y, width, self.lbl_TitleView.frame.size.height);

        if(_isShifted) {
            _isShifted = NO;
            self.lbl_TitleView.frame = CGRectMake(self.lbl_TitleView.frame.origin.x + MOVE_X, self.lbl_TitleView.frame.origin.y, width, self.lbl_TitleView.frame.size.height);

            self.lbl_Offline.frame = CGRectMake(self.lbl_Offline.frame.origin.x + MOVE_X + 10, self.lbl_Offline.frame.origin.y, self.lbl_Offline.frame.size.width, self.lbl_Offline.frame.size.height);
        }
    }
}

@end
