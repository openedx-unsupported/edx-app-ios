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

#import "MSIDIntuneInMemoryCacheDataSource.h"
#import "MSIDCache.h"

@interface MSIDIntuneInMemoryCacheDataSource ()

@property (nonatomic, readonly) MSIDCache *cache;

@end

@implementation MSIDIntuneInMemoryCacheDataSource

- (instancetype)initWithCache:(MSIDCache *)cache
{
    self = [super init];
    if (self)
    {
        _cache = cache ? cache : [MSIDCache new];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithCache:nil];
}

#pragma mark - MSIDIntuneCacheDataSource

- (NSDictionary *)jsonDictionaryForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

- (void)setJsonDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    [self.cache setObject:dictionary forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self.cache removeObjectForKey:key];
}

@end
