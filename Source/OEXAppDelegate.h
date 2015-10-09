//
//  OEXAppDelegate.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 15/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"

@class OEXCourse;

@interface OEXAppDelegate : UIResponder

@property (nonatomic, strong) id <Reachability> reachability;

- (void)callCompletionHandlerForSession:(NSString*)identifier;

@end
