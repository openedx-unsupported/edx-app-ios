//
//  OEXDownloadViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 13/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXCustomNavigationView.h"

@class RouterEnvironment;

NS_ASSUME_NONNULL_BEGIN

@interface OEXDownloadViewController : UIViewController <UITableViewDelegate>

@property (strong, nonatomic) RouterEnvironment* environment;

@end

NS_ASSUME_NONNULL_END
