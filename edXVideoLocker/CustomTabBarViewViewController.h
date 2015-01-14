//
//  CustomTabBarViewViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomNavigationView.h"
#import "DACircularProgressView.h"
#import "Course.h"
@class SWRevealViewController;

@interface CustomTabBarViewViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate , UITextViewDelegate>
{
}

#pragma classSelected
@property (nonatomic, retain) SWRevealViewController *obj_Reveal;
@property (nonatomic , assign) BOOL isNewCourseContentSelected;
@property (nonatomic,strong) Course *selectedCourse;

@end
