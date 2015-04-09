//
//  OEXApplication.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXApplication : UIApplication

+ (OEXApplication*)oex_sharedApplication;

- (void)interceptURLsWithHandler:(BOOL(^)(NSURL* url))handler whileExecuting:(void(^)(void))action;

@end
