//
//  OEXApplication.m
//  edXVideoLocker
//
//  Created by Akiva Leffert on 4/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXApplication.h"

typedef BOOL (^OEXURLHandler)(NSURL* url);

@interface OEXApplication ()

@property (strong, nonatomic) NSMutableArray* urlInterceptors;

@end

@implementation OEXApplication

+ (OEXApplication*)oex_sharedApplication {
    return OEXSafeCastAsClass([UIApplication sharedApplication], OEXApplication);
}

- (BOOL)openURL:(NSURL *)url {
    for(OEXURLHandler handler in self.urlInterceptors.reverseObjectEnumerator) {
        BOOL intercepted = handler(url);
        if(intercepted) {
            return NO;
        }
    }
    return [super openURL:url];
}

- (void)interceptURLsWithHandler:(BOOL(^)(NSURL* url))handler whileExecuting:(void(^)(void))action {
    if(self.urlInterceptors == nil) {
        self.urlInterceptors = [[NSMutableArray alloc] init];
    }
    if(handler) {
        [self.urlInterceptors addObject:handler];
    }

    action();

    if(handler) {
        [self.urlInterceptors removeLastObject];
    }
}

@end
