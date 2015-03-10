//
//  OEXFlowErrorViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXFlowErrorViewController : UIViewController

+ (id)sharedInstance;
- (void)animationUp;
- (void)animationDrop:(BOOL)shouldHide;
- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message onViewController:(UIView *)View shouldHide:(BOOL)hide;

@property (nonatomic, assign) BOOL errorMsgShouldHide;

@property (weak, nonatomic) IBOutlet UILabel *lbl_ErrorTitle;
@property (weak, nonatomic) IBOutlet UILabel *lbl_ErrorMessage;

@property (weak, nonatomic) IBOutlet UIView *bgUp;
@property (weak, nonatomic) IBOutlet UIView *bgDown;


@end
