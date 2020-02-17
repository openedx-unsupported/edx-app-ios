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

#import "MSIDKeyedArchiverSerializer.h"
#import "MSIDUserInformation.h"
#import "MSIDCredentialCacheItem.h"
#import "MSIDCredentialCacheItem+MSIDBaseToken.h"
#import "MSIDAccountCacheItem.h"
#import "MSIDLegacyTokenCacheItem.h"
#import "MSIDAppMetadataCacheItem.h"
#import "MSIDPRTCacheItem.h"
#import "NSKeyedArchiver+MSIDExtensions.h"
#import "NSKeyedUnarchiver+MSIDExtensions.h"

@implementation MSIDKeyedArchiverSerializer
{
    // class mapping for maintaining backward compatibility
    NSMutableDictionary *_defaultEncodeClassMap;
    NSMutableDictionary *_defaultDecodeClassMap;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        _defaultEncodeClassMap = [[NSMutableDictionary alloc] initWithDictionary:@{@"ADUserInformation" : MSIDUserInformation.class,
                                                                                   @"ADTokenCacheStoreItem" : MSIDLegacyTokenCacheItem.class
                                                                                   }];
        _defaultDecodeClassMap = [[NSMutableDictionary alloc] initWithDictionary:@{@"ADUserInformation" : MSIDUserInformation.class,
                                                                                   @"ADBrokerPRTCacheItem" : MSIDPRTCacheItem.class
                                                                                   }];
    }
    
    return self;
}

#pragma mark - Private

- (NSData *)serialize:(MSIDCredentialCacheItem *)item
{
    if (!item) return nil;
    
    // In order to customize the archiving process Apple recommends to create an instance of the archiver and
    // customize it (instead of using share NSKeyedArchiver).
    // See here: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/Archiving/Articles/creating.html
    NSData *result = [NSKeyedArchiver msidEncodeObject:item usingBlock:^(NSKeyedArchiver *archiver)
    {
        // Maintain backward compatibility with ADAL.
        for (NSString *className in _defaultEncodeClassMap)
        {
            [archiver setClassName:className forClass:_defaultEncodeClassMap[className]];
        }
    }];
    
    return result;
}

- (MSIDLegacyTokenCacheItem *)deserialize:(NSData *)data className:(Class)className
{
    if (!data)
    {
        return nil;
    }
    
    NSError *error;
    NSKeyedUnarchiver *unarchiver = [NSKeyedUnarchiver msidCreateForReadingFromData:data error:&error];
    if (error)
    {
        MSID_LOG_WITH_CTX_PII(MSIDLogLevelError, nil, @"Failed to deserialize data, error: %@", MSID_PII_LOG_MASKABLE(error));
        return nil;
    }
    
    // Maintain backward compatibility with ADAL.
    [unarchiver setClass:className forClassName:@"ADTokenCacheStoreItem"];
    for (NSString *defaultClassName in _defaultDecodeClassMap)
    {
        [unarchiver setClass:_defaultDecodeClassMap[defaultClassName] forClassName:defaultClassName];
    }
    
    MSIDLegacyTokenCacheItem *token = [unarchiver decodeObjectOfClass:className forKey:NSKeyedArchiveRootObjectKey];
    [unarchiver finishDecoding];
    
    return token;
}

#pragma mark - Token

- (NSData *)serializeCredentialCacheItem:(MSIDCredentialCacheItem *)item
{
    if (![item isKindOfClass:[MSIDLegacyTokenCacheItem class]])
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Asked to serialize MSIDCredentialCacheItem, which is unsupported");
        return nil;
    }

    return [self serialize:item];
}

- (MSIDCredentialCacheItem *)deserializeCredentialCacheItem:(NSData *)data
{
    MSIDLegacyTokenCacheItem *item = [self deserialize:data className:MSIDLegacyTokenCacheItem.class];
    
    // Because theoretically any item data can be passed in here for deserialization,
    // we need to ensure that the correct item got deserialized
    if ([item isKindOfClass:[MSIDLegacyTokenCacheItem class]])
    {
        return (MSIDLegacyTokenCacheItem *) item;
    }
    
    return nil;
}

- (NSData *)serializeCredentialStorageItem:(__unused MSIDMacCredentialStorageItem *)item
{
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Asked to serialize MSIDMacCredentialStorageItem, which is unsupported");
    return nil;
}

- (MSIDMacCredentialStorageItem *)deserializeCredentialStorageItem:(__unused NSData *)data
{
    MSID_LOG_WITH_CTX(MSIDLogLevelWarning,nil, @"Asked to deserialize MSIDMacCredentialStorageItem, which is unsupported");
    return nil;
}

#pragma mark - Class Mapping

- (void)addEncodeClassMapping:(NSDictionary *)classMap
{
    if (!classMap) return;
    
    [_defaultEncodeClassMap addEntriesFromDictionary:classMap];
}

- (void)addDecodeClassMapping:(NSDictionary *)classMap
{
    if (!classMap) return;
    
    [_defaultDecodeClassMap addEntriesFromDictionary:classMap];
}

@end
