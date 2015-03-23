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
#import "OEXInterface.h"
#import "OEXCustomEditingView.h"
#import "OEXRevealContentViewController+Protected.h"

@interface OEXMyVideosViewController : OEXRevealContentViewController <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate >

- (void)removeAllObserver;
@end
