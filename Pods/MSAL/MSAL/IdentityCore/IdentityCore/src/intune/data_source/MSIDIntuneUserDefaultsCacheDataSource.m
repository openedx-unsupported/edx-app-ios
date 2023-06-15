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

#import "MSIDIntuneUserDefaultsCacheDataSource.h"
#import "MSIDJsonSerializer.h"
#import "NSDictionary+MSIDJsonSerializable.h"

@interface MSIDIntuneUserDefaultsCacheDataSource ()

@property (nonatomic, readonly) NSUserDefaults *userDefaults;
@property (nonatomic, readonly) MSIDJsonSerializer *jsonSerializer;

@end

@implementation MSIDIntuneUserDefaultsCacheDataSource

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self)
    {
        _userDefaults = userDefaults ? userDefaults : NSUserDefaults.standardUserDefaults;
        _jsonSerializer = [MSIDJsonSerializer new];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithUserDefaults:nil];
}

#pragma mark - MSIDIntuneCacheDataSource

- (NSDictionary *)jsonDictionaryForKey:(NSString *)key
{
    NSString *jsonString = [self.userDefaults objectForKey:key];
    if ([NSString msidIsStringNilOrBlank:jsonString]) return nil;
    
    return (NSDictionary *)[self.jsonSerializer fromJsonString:jsonString
                                                        ofType:NSDictionary.self
                                                       context:nil
                                                         error:nil];
}

- (void)setJsonDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    NSString *jsonString = [self.jsonSerializer toJsonString:dictionary
                                                     context:nil
                                                       error:nil];
    
    [self.userDefaults setObject:jsonString forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    [self.userDefaults removeObjectForKey:key];
}

@end
