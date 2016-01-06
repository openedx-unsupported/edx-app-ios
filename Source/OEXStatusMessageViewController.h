//
//  OEXStatusMessageViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 07/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXStatusMessageViewController;
@class OEXTextStyle;

extern CGFloat const OEXStatusMessagePadding;

@protocol OEXStatusMessageControlling <NSObject>

/// How far below the view origin the status message should be displayed
/// Typically this is the height of the navigation bar (including status bar),
/// but may also, for example, include a tab bar
- (CGFloat)verticalOffsetForStatusController:(OEXStatusMessageViewController*)controller;

// Similarly, most of these views are from the navigation bar, so if we're using the system navigation bar
// These will just naturally go under that. For the tab bar, if we factor each tab to be a separate controller
// as they should be, these will naturally be zero

/// Views that show be *over* the status message. Typically navigation related views
- (NSArray*)overlayViewsForStatusController:(OEXStatusMessageViewController*)controller;

@end

// DEPRECATED. Instead use the helpers in UIViewController+Overlay.swift
@interface OEXStatusMessageViewController : UIViewController

+ (instancetype)sharedInstance;

+ (OEXTextStyle*)statusMessageStyle;

- (void)showMessage:(NSString*)message onViewController:(UIViewController <OEXStatusMessageControlling>*)controller;

@property (readonly, nonatomic) BOOL isVisible;

@end

// Should only be used from within unit tests
@interface OEXStatusMessageViewController (Testing)

- (BOOL)t_doesMessageTextFit;
- (BOOL)t_isStatusViewBelowView:(UIView*)view;

@end

NS_ASSUME_NONNULL_END
