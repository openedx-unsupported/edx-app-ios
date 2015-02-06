//
//  OEXCustomTabBarViewViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXCustomNavigationView.h"
#import "DACircularProgressView.h"
#import "OEXCourse.h"

@class SWRevealViewController;

@interface OEXCustomTabBarViewViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate , UITextViewDelegate>
{
}
@property (nonatomic, strong) NSSet* offlineAvailableChapterIDs;

#pragma classSelected
@property (nonatomic, retain) SWRevealViewController *obj_Reveal;
@property (nonatomic , assign) BOOL isNewCourseContentSelected;
@property (nonatomic,strong) OEXCourse *selectedCourse;

@end
