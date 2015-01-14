//
//  CourseVideoDownloadTableViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 26/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EdXInterface.h"
#import "CustomNavigationView.h"
#import "DACircularProgressView.h"
#import "CustomLabel.h"
#import "CustomEditingView.h"


@interface CourseVideoDownloadTableViewController : UIViewController <UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource>
@property (strong,nonatomic)  HelperVideoDownload *lastAccessedVideo;
@property (nonatomic, assign) BOOL isFromGenericView;
@property (nonatomic, strong) NSMutableArray *arr_DownloadProgress;
@property (nonatomic, strong) NSMutableArray *arr_OfflineData;
@property (strong, nonatomic) NSString *str_SelectedChapName;
@property (strong, nonatomic) NSURL * currentVideoURL;

@end
