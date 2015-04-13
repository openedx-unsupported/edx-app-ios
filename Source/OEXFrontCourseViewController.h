//
//  OEXFrontCourseViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXInterface.h"
#import "DACircularProgressView.h"
#import <MessageUI/MessageUI.h>
#import "SWRevealViewController.h"
#import "OEXRevealContentViewController+Protected.h"

@interface OEXFrontCourseViewController : OEXRevealContentViewController <UITableViewDataSource, UITableViewDelegate>

@end
