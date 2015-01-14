//
//  MyVideosViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DACircularProgressView.h"
#import <MessageUI/MessageUI.h>
#import "SWRevealViewController.h"
#import "EdXInterface.h"
#import "CustomEditingView.h"


@interface MyVideosViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, SWRevealViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate >

- (IBAction)overlayButtonTapped:(id)sender;
-(void)removeAllObserver;
@end
