//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#import "MSIDBackgroundTaskManager.h"
#import "MSIDAppExtensionUtil.h"
#import "MSIDCache.h"

@interface MSIDBackgroundTaskManager()

@property (nonatomic) MSIDCache *taskCache;

@end

@implementation MSIDBackgroundTaskManager

#pragma mark - Init

- (id)initInternal
{
    self = [super init];
    if (self)
    {
        _taskCache = [MSIDCache new];
    }
    return self;
}

+ (MSIDBackgroundTaskManager *)sharedInstance
{
    static dispatch_once_t once;
    static MSIDBackgroundTaskManager *singleton = nil;
    
    dispatch_once(&once, ^{
        singleton = [[MSIDBackgroundTaskManager alloc] initInternal];
    });
    
    return singleton;
}

#pragma mark - Implementation

/*
 Background task execution:
 https://forums.developer.apple.com/message/253232#253232
 */

- (void)startOperationWithType:(MSIDBackgroundTaskType)type
{
    UIBackgroundTaskIdentifier backgroundTask = [self backgroundTaskWithType:type];
    
    if (backgroundTask != UIBackgroundTaskInvalid)
    {
        // Background task already started
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Start background app task with type %ld", (long)type);
    
    backgroundTask = [[MSIDAppExtensionUtil sharedApplication] beginBackgroundTaskWithName:@"Interactive login"
                                                                  expirationHandler:^{
                                                                      MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Background task expired for type %ld", (long)type);
                                                                      [self stopOperationWithType:type];
                                                                  }];
    
    [self setBackgroundTask:backgroundTask forType:type];
}

- (void)stopOperationWithType:(MSIDBackgroundTaskType)type
{
    UIBackgroundTaskIdentifier backgroundTask = [self backgroundTaskWithType:type];
    
    if (backgroundTask == UIBackgroundTaskInvalid)
    {
        // Background task not started
        return;
    }
    
    MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Stop background task with type %ld", (long)type);
    [[MSIDAppExtensionUtil sharedApplication] endBackgroundTask:backgroundTask];
    [self setBackgroundTask:UIBackgroundTaskInvalid forType:type];
}

#pragma mark - Task dictionary

- (UIBackgroundTaskIdentifier)backgroundTaskWithType:(MSIDBackgroundTaskType)type
{
    return [[self.taskCache objectForKey:@(type)] integerValue];
}

- (void)setBackgroundTask:(UIBackgroundTaskIdentifier)backgroundTask forType:(MSIDBackgroundTaskType)type
{
    [self.taskCache setObject:@(backgroundTask) forKey:@(type)];
}

@end
