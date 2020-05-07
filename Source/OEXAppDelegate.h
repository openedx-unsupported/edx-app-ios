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

- (void)callCompletionHandlerForSession:(NSString*)identifier;
- (void)initilizeChromeCast;

@end

NS_ASSUME_NONNULL_END
