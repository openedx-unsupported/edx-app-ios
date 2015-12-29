//
//  OEXEnrollmentMessage.m
//  edXVideoLocker
//
//  Created by Abhradeep on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXEnrollmentMessage.h"

@implementation OEXEnrollmentMessage

- (id)initWithMessage:(NSString *)message shouldReloadTable:(BOOL)shouldReload {
    self = [super init];
    if(self != nil) {
        self.messageBody = message;
        self.shouldReloadTable = shouldReload;
    }
    return self;
}

@end
