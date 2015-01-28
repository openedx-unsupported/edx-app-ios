//
//  OEXFindCourseInterstitialViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 28/01/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OEXFindCourseInterstitialViewControllerDelegate <NSObject>
-(void)interstitialViewControllerDidChooseToOpenInBrowser:(id)interstitialViewController;
-(void)interstitialViewControllerDidClose:(id)interstitialViewController;
@end

@interface OEXFindCourseInterstitialViewController : UIViewController
@property (nonatomic, weak) id <OEXFindCourseInterstitialViewControllerDelegate> delegate;
@end
