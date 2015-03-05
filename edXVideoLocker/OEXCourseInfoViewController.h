//
//  OEXCourseInfoViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXRevealOptionsViewController+Protected.h"

@interface OEXCourseInfoViewController : OEXRevealOptionsViewController

- (instancetype)initWithPathID:(NSString*)pathID;

@end