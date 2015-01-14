//
//  FrontCourseViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EdXInterface.h"
#import "DACircularProgressView.h"
#import <MessageUI/MessageUI.h>
#import "SWRevealViewController.h"

@interface FrontCourseViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, SWRevealViewControllerDelegate>

@end
