//
//  OEXFindCourseInterstitialViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OEXFindCourseInterstitialViewController;

@protocol OEXFindCourseInterstitialViewControllerDelegate <NSObject>
-(void)interstitialViewControllerDidChooseToOpenInBrowser:(OEXFindCourseInterstitialViewController*)interstitialViewController;
-(void)interstitialViewControllerDidClose:(OEXFindCourseInterstitialViewController*)interstitialViewController;
@end

@interface OEXFindCourseInterstitialViewController : UIViewController
@property (weak, nonatomic) id <OEXFindCourseInterstitialViewControllerDelegate> delegate;
@end
