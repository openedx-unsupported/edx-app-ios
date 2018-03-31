//
//  CLButton.m
//  CLMoviePlayer
//
//  Created by Jotiram Bhagat on 25/06/14.
//  Copyright (c) 2014 Jotiram Bhagat. All rights reserved.
//

#import "CLButton.h"
static const CGFloat expandedMargin = 10.f;

@implementation CLButton

- (id)init {
    if(self = [super init]) {
        self.showsTouchWhenHighlighted = YES;
//        [self addTarget:self action:@selector(touchedDown:) forControlEvents:UIControlEventTouchDown];
//        [self addTarget:self action:@selector(touchedUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
//        [self addTarget:self action:@selector(touchCancelled:) forControlEvents:UIControlEventTouchCancel];
    }
    return self;
}

- (void)touchedDown:(UIButton*)button {
    if([self.delegate respondsToSelector:@selector(buttonTouchedDown:)]) {
        [self.delegate buttonTouchedDown:self];
    }
}

- (void)touchedUpOutside:(UIButton*)button {
    if([self.delegate respondsToSelector:@selector(buttonTouchedUpOutside:)]) {
        [self.delegate buttonTouchedUpOutside:self];
    }
}

- (void)touchCancelled:(UIButton*)button {
    if([self.delegate respondsToSelector:@selector(buttonTouchCancelled:)]) {
        [self.delegate buttonTouchCancelled:self];
    }
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event {
    CGRect expandedFrame = CGRectMake(0 - expandedMargin, 0 - expandedMargin, self.frame.size.width + (expandedMargin * 2), self.frame.size.height + (expandedMargin * 2));
    return (CGRectContainsPoint(expandedFrame, point) == 1) ? self : nil;
}

@end
