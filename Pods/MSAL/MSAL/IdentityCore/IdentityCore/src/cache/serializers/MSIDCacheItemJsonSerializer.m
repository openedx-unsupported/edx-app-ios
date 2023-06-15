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

#import "MSIDCacheItemJsonSerializer.h"
#import "MSIDJsonSerializer.h"
#import "MSIDJsonSerializable.h"
#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDAppMetadataCacheItem.h"
#import "MSIDAccountMetadata.h"
#import "MSIDJsonObject.h"

#if !TARGET_OS_IPHONE
#import "MSIDMacCredentialStorageItem.h"
#endif

@interface MSIDCacheItemJsonSerializer()

@property (nonatomic) id<MSIDJsonSerializing> jsonSerializer;

@end

@implementation MSIDCacheItemJsonSerializer

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _jsonSerializer = [MSIDJsonSerializer new];
    }
    return self;
}

#pragma mark - Token

- (NSData *)serializeCredentialCacheItem:(MSIDCredentialCacheItem *)item
{
    return [self.jsonSerializer toJsonData:item context:nil error:nil];
}

- (MSIDCredentialCacheItem *)deserializeCredentialCacheItem:(NSData *)data
{
    return (MSIDCredentialCacheItem *)[self deserializeCacheItem:data ofClass:[MSIDCredentialCacheItem class]];
}

#if TARGET_OS_OSX

- (NSData *)serializeCredentialStorageItem:(MSIDMacCredentialStorageItem *)item
{
    return [self.jsonSerializer toJsonData:item context:nil error:nil];
}

- (MSIDMacCredentialStorageItem *)deserializeCredentialStorageItem:(NSData *)data
{
    return (MSIDMacCredentialStorageItem *)[self deserializeCacheItem:data ofClass:[MSIDMacCredentialStorageItem class]];
}

#endif

#pragma mark - JSON Object

- (NSData *)serializeCacheItem:(id<MSIDJsonSerializable>)item
{
    return [self.jsonSerializer toJsonData:item context:nil error:nil];
}

- (id<MSIDJsonSerializable>)deserializeCacheItem:(NSData *)data ofClass:(Class)expectedClass
{
    NSError *error = nil;
    id<MSIDJsonSerializable> item = [self.jsonSerializer fromJsonData:data ofType:expectedClass context:nil error:&error];
    
    if (!item)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, nil, @"Failed to deserialize object %@ of expected class %@", error, expectedClass);
        return nil;
    }
    
    return item;
}

@end
