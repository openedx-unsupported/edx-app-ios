//
//  OEXOpenInBrowserViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 19/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// TODO replace this with a standard view we can add to a screen
// There's no reason for this to be a singleton
@interface OEXOpenInBrowserViewController : UIViewController

+ (id)sharedInstance;

- (void)addViewToSuperview:(UIView*)parentView;
- (void)addViewToContainerSuperview:(UIView*)parentView;
- (void)removeSelfFromSuperView;

@property (weak, nonatomic, nullable) IBOutlet UIButton* openInBrowserClicked;
@property (nonatomic, strong, nullable) NSString* str_browserURL;
@property (weak, nonatomic, nullable) IBOutlet UIView* view_BG;

@property (weak, nonatomic, nullable) IBOutlet UIButton* btn_OpenInBrowser;
@property (weak, nonatomic, nullable) IBOutlet UILabel* lbl_Title;

- (IBAction)openInBrowserClicked:(id)sender;

@end

NS_ASSUME_NONNULL_END
