//
//  OEXEnvironment.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 12/29/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OEXConfig;
@class OEXRouter;

@interface OEXEnvironment : NSObject

- (void)setConfigBuilder:(OEXConfig*(^)(void))config;
- (void)setRouterBuilder:(OEXRouter*(^)(void))router;

- (void)setupEnvironment;

@end
