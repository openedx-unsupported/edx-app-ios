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


@interface OEXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//Core data
@property (copy, nonatomic) void (^backgroundSessionCompletionHandler)();
@property(nonatomic) BOOL isSocialMediaLogin;
@property(nonatomic) BOOL isSocialURLDelegateCalled;

@property (nonatomic, strong) NSMutableDictionary *dict_VideoSummary;
@property (nonatomic, strong) SWRevealViewController *revealController;
@property (nonatomic, strong) Reachability * reachability;
@property (nonatomic,assign) BOOL handleFacebookSchema;
@property (nonatomic,assign) BOOL handleGoogleSchema;


//To launch email view from rear view
@property (nonatomic, assign) BOOL pendingMailComposerLaunch;

- (void)deactivate;
- (void)callCompletionHandlerForSession: (NSString *)identifier;


@end
