//
//  DownloadViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomNavigationView.h"

@interface DownloadViewController : UIViewController <UITableViewDelegate>

@property (nonatomic, assign)BOOL isFromFrontViews;
@property (nonatomic, assign)BOOL isFromGenericViews;
@end
