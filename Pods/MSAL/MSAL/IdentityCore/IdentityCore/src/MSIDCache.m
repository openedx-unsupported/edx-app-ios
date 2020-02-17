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
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDCache.h"

@interface MSIDCache ()

@property (nonatomic) NSMutableDictionary *container;
@property (nonatomic) dispatch_queue_t synchronizationQueue;

@end

@implementation MSIDCache

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    
    if (self)
    {
        NSString *queueName = [NSString stringWithFormat:@"com.microsoft.msidcache-%@", [NSUUID UUID].UUIDString];
        _synchronizationQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        
        _container = dictionary ? [dictionary mutableCopy] : [NSMutableDictionary new];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithDictionary:nil];
}

- (id)objectForKey:(id)key
{
    __block id object;
    dispatch_sync(self.synchronizationQueue, ^{
        object = self.container[key];
    });
    
    return object;
}

- (void)setObject:(id)obj forKey:(id)key
{
    dispatch_barrier_async(self.synchronizationQueue, ^{
        self.container[key] = obj;
    });
}

- (void)removeObjectForKey:(id)key
{
    dispatch_barrier_async(self.synchronizationQueue, ^{
        [self.container removeObjectForKey:key];
    });
}

- (void)removeAllObjects
{
    dispatch_barrier_async(self.synchronizationQueue, ^{
        [self.container removeAllObjects];
    });
}

- (NSDictionary *)toDictionary
{
    __block NSDictionary *dictionary;
    dispatch_sync(self.synchronizationQueue, ^{
        dictionary = [self.container copy];
    });
    
    return dictionary;
}

- (NSUInteger)count
{
    __block NSUInteger count = 0;
    dispatch_sync(self.synchronizationQueue, ^{
        count = self.container.allKeys.count;
    });
    
    return count;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDCache *item = [[self.class allocWithZone:zone] init];
    item->_container = [_container copyWithZone:zone];
    
    return item;
}

@end
