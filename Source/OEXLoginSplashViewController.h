//
//  LoginSplashViewController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXRouter;

@interface OEXLoginSplashViewControllerEnvironment : NSObject

- (id)initWithRouter:(OEXRouter*)router;

@property (weak, nonatomic) OEXRouter* router;

@end

@interface OEXLoginSplashViewController : UIViewController

- (id)initWithEnvironment:(OEXLoginSplashViewControllerEnvironment*)environment;

@end
