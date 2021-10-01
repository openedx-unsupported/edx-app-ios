//
//  OEXAppDelegate.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

@import UIKit;
#import "Reachability.h"

NS_ASSUME_NONNULL_BEGIN

@class OEXCourse;

@interface OEXAppDelegate : UIResponder

@property (nonatomic, strong) id <Reachability> reachability;
/// This will be used to figureout either the app was opened from the deep link or not. This will be used to perfome app banner functionality
@property (nonatomic, assign) BOOL openedFromDeeplink;

- (void)callCompletionHandlerForSession:(NSString*)identifier;

@end

NS_ASSUME_NONNULL_END
