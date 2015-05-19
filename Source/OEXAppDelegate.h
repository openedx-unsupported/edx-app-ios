//
//  OEXAppDelegate.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "SWRevealViewController.h"

@class OEXCourse;

@interface OEXAppDelegate : UIResponder

@property (nonatomic, strong) id <Reachability> reachability;

//To launch email view from rear view
@property (nonatomic, assign) BOOL pendingMailComposerLaunch;

- (void)callCompletionHandlerForSession:(NSString*)identifier;

@end
