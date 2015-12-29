//
//  OEXStatusMessageViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStatusMessageViewController.h"

#import "OEXTextStyle.h"

static CGFloat const OEXStatusMessagePadding = 20;

@interface OEXStatusMessageViewController ()

@property (strong, nonatomic) IBOutlet UILabel* statusLabel;
@property (nonatomic, assign) CGFloat messageY;

@end

@implementation OEXStatusMessageViewController

+ (id)sharedInstance {
    static OEXStatusMessageViewController* sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[OEXStatusMessageViewController alloc] init];
    });

    return sharedController;
}

+ (OEXTextStyle*)statusMessageStyle {
    OEXMutableTextStyle* style = [[OEXMutableTextStyle alloc] initWithWeight:OEXTextWeightNormal size:OEXTextSizeSmall color:[UIColor whiteColor]];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    return style;
}

- (CGFloat)labelPadding {
    return OEXStatusMessagePadding * 2; // one for each side
}

#pragma mark Public Actions

- (void)showMessage:(NSString*)message onViewController:(UIViewController <OEXStatusMessageControlling>*)controller {
    //Remove previous instance and animation
    [self.view removeFromSuperview];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    (void)self.view; // ensure view is loaded

    //Pass data
    self.statusLabel.attributedText = [[[self class] statusMessageStyle] attributedStringWithText: message];

    CGFloat height = ceil([self.statusLabel sizeThatFits:CGSizeMake(controller.view.bounds.size.width - [self labelPadding], CGFLOAT_MAX)].height);
    height += [self labelPadding]; // top + bottom

    self.view.frame = CGRectMake(0,
                                 -height,
                                 controller.view.bounds.size.width,
                                 height);

    NSArray* overlayViews = [controller overlayViewsForStatusController:self] ? : @[];

    // Unfortunately, because of the way our nav bars are set up (as part of the controller, instead of
    // in a containing UINavigationController), we need to ensure that those views are at the top of the view
    // ordering, so that we can put the status message under them. This floats them all to the top
    // while maintaining their ordering
    overlayViews = [overlayViews sortedArrayUsingComparator:^NSComparisonResult (UIView* view1, UIView* view2) {
        return [@([controller.view.subviews indexOfObject:view1])compare : @([controller.view.subviews indexOfObject:view2])];
    }];

    for(UIView* overlay in overlayViews) {
        [controller.view bringSubviewToFront:overlay];
    }

    if(overlayViews.count == 0) {
        [controller.view addSubview:self.view];
    }
    else {
        [controller.view insertSubview:self.view belowSubview:overlayViews.firstObject];
    }

    self.messageY = [controller verticalOffsetForStatusController:self];

    //Animate
    [self animationDrop];
}

#pragma mark Animation

- (void)animationDrop {
    [UIView animateWithDuration:ANI_DURATION
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.view.frame = CGRectMake(0,
                                     _messageY,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);
    } completion:^(BOOL finished) {
        [self performSelector:@selector(animationUp) withObject:nil afterDelay:ANI_ERROR_TIMEOUT];
    }];
}

- (void)animationUp {
    [UIView animateWithDuration:ANI_DURATION
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:0.1
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        CGFloat height = self.view.frame.size.height;
        self.view.frame = CGRectMake(0, -height, self.view.frame.size.width, height);
    } completion:nil];
}

- (BOOL)isVisible {
    return self.isViewLoaded && self.view.window != nil;
}

@end

@implementation OEXStatusMessageViewController (Testing)

- (BOOL)t_doesMessageTextFit {
    CGRect bounds = self.statusLabel.bounds;
    CGSize size = [self.statusLabel sizeThatFits:CGSizeMake(bounds.size.width, CGFLOAT_MAX)];
    return ceil(size.height + [self labelPadding]) == ceil(bounds.size.height) && self.view.bounds.size.width == self.view.superview.bounds.size.width;
}

- (BOOL)t_isStatusViewBelowView:(UIView*)view {
    NSInteger statusIndex = [self.view.superview.subviews indexOfObject:self.view];
    NSInteger viewIndex = [self.view.superview.subviews indexOfObject:view];
    return statusIndex < viewIndex;
}

@end