//
//  LoginSplashViewController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 16/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class OEXRouter;

@interface OEXLoginSplashViewControllerEnvironment : NSObject

- (id)initWithRouter:(OEXRouter*)router;

@property (weak, nonatomic) OEXRouter* router;

@end

@interface OEXLoginSplashViewController : UIViewController

- (id)initWithEnvironment:(OEXLoginSplashViewControllerEnvironment*)environment;

@end

NS_ASSUME_NONNULL_END
