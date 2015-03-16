//
//  OEXOpenInBrowserViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 19/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXOpenInBrowserViewController : UIViewController

+ (id)sharedInstance;
- (void)addViewToSuperview:(UIView*)parentView;
- (void)addViewToContainerSuperview:(UIView*)parentView;
- (void)removeSelfFromSuperView;

@property (weak, nonatomic) IBOutlet UIButton* openInBrowserClicked;
@property (nonatomic, strong) NSString* str_browserURL;
@property (weak, nonatomic) IBOutlet UIView* view_BG;

@property (weak, nonatomic) IBOutlet UIButton* btn_OpenInBrowser;
@property (weak, nonatomic) IBOutlet UILabel* lbl_Title;
- (IBAction)openInBrowserClicked:(id)sender;
@end
