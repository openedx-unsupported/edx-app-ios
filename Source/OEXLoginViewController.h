//
//  OEXLoginViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXLoginViewController;

@protocol OEXLoginViewControllerDelegate <NSObject>

- (void)loginViewControllerDidLogin:(OEXLoginViewController*)loginController;

@end

@interface OEXLoginViewController : UIViewController

@property (weak, nonatomic) id <OEXLoginViewControllerDelegate> delegate;

@end
