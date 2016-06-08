//
//  OEXFlowErrorViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface OEXFlowErrorViewController : UIViewController

+ (instancetype)sharedInstance;
- (void)animationUp;
- (void)showHidingAutomatically:(BOOL)shouldHide;
- (void)showErrorWithTitle:(NSString*)title message:(NSString*)message onViewController:(UIView*)View shouldHide:(BOOL)hide;
- (void)showNoConnectionErrorOnView:(UIView*)view;
- (void)updateViewFrameWithParentView:(UIView *) view;

@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_ErrorTitle;
@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_ErrorMessage;

@property (weak, nonatomic, nullable) IBOutlet UIView* bgUp;
@property (weak, nonatomic, nullable) IBOutlet UIView* bgDown;

@end

NS_ASSUME_NONNULL_END
