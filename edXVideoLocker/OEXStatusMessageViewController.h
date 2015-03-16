//
//  OEXStatusMessageViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 07/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXStatusMessageViewController : UIViewController

+ (id)sharedInstance;

@property (weak, nonatomic) IBOutlet UIView* view_Container;
@property (weak, nonatomic) IBOutlet UILabel* statusLabel;
@property (nonatomic, assign) float messageY;
@property (nonatomic, assign) BOOL errorMsgShouldHide;

- (void)showMessage:(NSString*)message
    onViewController:(UIView*)View
    messageY:(float)messageY
    shouldHide:(BOOL)hide;

- (void)showMessage:(NSString*)message
    onViewController:(UIView*)View
    messageY:(float)messageY
    components:(NSArray*)comps
    shouldHide:(BOOL)hide;

@end
