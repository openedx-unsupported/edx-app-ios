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


@interface OEXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//Core data
@property (copy, nonatomic) void (^backgroundSessionCompletionHandler)();
@property(nonatomic)BOOL isSocialMediaLogin;
@property(nonatomic)BOOL isSocialURLDelegateCalled;
@property (nonatomic, strong) NSMutableString *str_NAVTITLE;
@property (nonatomic, strong) NSMutableString *str_HANDOUTS_URL;
@property (nonatomic, strong) NSMutableString *str_ANNOUNCEMENTS_URL;
@property (nonatomic, strong) NSMutableString *str_COURSE_ABOUT_URL;
@property (nonatomic, strong) NSMutableString *str_COURSE_OUTLINE_URL;
@property (nonatomic,strong)NSMutableString *str_selected_course;

@property (nonatomic, strong) NSMutableDictionary *dict_VideoSummary;
@property(nonatomic,strong) SWRevealViewController *revealController;
@property (nonatomic, strong) Reachability * reachability;
@property(nonatomic,assign)BOOL handleFacebookSchema;
@property(nonatomic,assign)BOOL handleGoogleSchema;


//To launch email view from rear view
@property (nonatomic, assign) BOOL pendingMailComposerLaunch;

- (NSString *)convertDate:(NSString *)strReceiveDate;
- (BOOL)isDateOld:(NSString *)startdate;
- (void)deactivate;
+ (NSString *)appVersion;
+ (NSString *)timeFormatted:(NSString *)totalSeconds;
- (void)callCompletionHandlerForSession: (NSString *)identifier;


@end
