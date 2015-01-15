//
//  OEXMyVideosViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DACircularProgressView.h"
#import <MessageUI/MessageUI.h>
#import "SWRevealViewController.h"
#import "OEXInterface.h"
#import "OEXCustomEditingView.h"


@interface OEXMyVideosViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, SWRevealViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate >

- (IBAction)overlayButtonTapped:(id)sender;
-(void)removeAllObserver;
@end
