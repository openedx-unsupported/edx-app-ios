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
#import "MSIDBackgroundTaskData.h"

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
 https://developer.apple.com/forums/thread/85066
 */

- (void)startOperationWithType:(MSIDBackgroundTaskType)type
{
    @synchronized (self.taskCache)
    {
        MSIDBackgroundTaskData *backgroundTaskData = [self backgroundTaskWithType:type];
        if (backgroundTaskData)
        {
            // A background task was already started for this type, updating count
            backgroundTaskData.callerReferenceCount++;
            return;
        }
        UIBackgroundTaskIdentifier backgroundTaskId = [[MSIDAppExtensionUtil sharedApplication] beginBackgroundTaskWithName:@"Interactive login"
                                                                                                          expirationHandler:^{
                                                                        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Background task expired for type %ld.", (long)type);
                                                                    // If a task took too long & OS has decided to kill it, end bg task for that type regardless of other requsts relying on bg protection.
                                                                        [self expireOperationWithType:type];
                                                                    }];
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Start background app task with type %ld & taskId : %lu", (long)type, (unsigned long)backgroundTaskId);
        [self setBackgroundTask:[[MSIDBackgroundTaskData alloc] initWithTaskId:backgroundTaskId] forType:type];
    }
}

- (void)stopOperationWithType:(MSIDBackgroundTaskType)type
{
    @synchronized (self.taskCache)
    {
        MSIDBackgroundTaskData *backgroundTaskData = [self backgroundTaskWithType:type];
        backgroundTaskData.callerReferenceCount--;
        if (!backgroundTaskData || backgroundTaskData.callerReferenceCount > 0)
        {
            // No background task found in task cache for specified type or there are still other tasks relying on background protection.
            return;
        }
        MSID_LOG_WITH_CTX(MSIDLogLevelInfo, nil, @"Stop background task with type %ld & taskId : %lu", (long)type, backgroundTaskData.backgroundTaskId);
        [[MSIDAppExtensionUtil sharedApplication] endBackgroundTask:backgroundTaskData.backgroundTaskId];
        [self.taskCache removeObjectForKey:@(type)];
    }
}

- (void)expireOperationWithType:(MSIDBackgroundTaskType)type
{
    MSIDBackgroundTaskData *backgroundTaskData = [self backgroundTaskWithType:type];
    backgroundTaskData.callerReferenceCount = 1;
    [self stopOperationWithType:type];
}

#pragma mark - Task dictionary

- (MSIDBackgroundTaskData *)backgroundTaskWithType:(MSIDBackgroundTaskType)type
{
    return [self.taskCache objectForKey:@(type)];
}

- (void)setBackgroundTask:(MSIDBackgroundTaskData *)backgroundTaskData forType:(MSIDBackgroundTaskType)type
{
    [self.taskCache setObject:backgroundTaskData forKey:@(type)];
}

@end
