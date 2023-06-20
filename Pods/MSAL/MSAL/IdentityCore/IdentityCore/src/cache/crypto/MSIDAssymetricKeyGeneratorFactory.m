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

#import "MSIDAssymetricKeyGeneratorFactory.h"
#import "MSIDAssymetricKeyKeychainGenerator.h"
#import "MSIDKeychainTokenCache.h"
#if !TARGET_OS_IPHONE
#import "MSIDMacKeychainTokenCache.h"
#import "MSIDAssymetricKeyLoginKeychainGenerator.h"
#endif
#import "MSIDCacheConfig.h"

@implementation MSIDAssymetricKeyGeneratorFactory

+ (id<MSIDAssymetricKeyGenerating>)defaultKeyGeneratorWithCacheConfig:(MSIDCacheConfig *)cacheConfig error:(NSError **)error
{
#if TARGET_OS_IPHONE
    return [self iOSDefaultKeyGeneratorWithCacheConfig:cacheConfig error:error];
#else
    return [self macDefaultKeyGeneratorWithCacheConfig:cacheConfig error:error];
#endif
}

+ (id<MSIDAssymetricKeyGenerating>)iOSDefaultKeyGeneratorWithCacheConfig:(MSIDCacheConfig *)cacheConfig error:(NSError **)error
{
    return [[MSIDAssymetricKeyKeychainGenerator alloc] initWithGroup:cacheConfig.keychainGroup error:error];
}

#if !TARGET_OS_IPHONE
+ (id<MSIDAssymetricKeyGenerating>)macDefaultKeyGeneratorWithCacheConfig:(MSIDCacheConfig *)cacheConfig error:(NSError **)error
{
    if (@available(macOS 10.15, *))
    {
        return [[MSIDAssymetricKeyKeychainGenerator alloc] initWithGroup:cacheConfig.keychainGroup error:error];
    }
    else
    {
        return [[MSIDAssymetricKeyLoginKeychainGenerator alloc] initWithKeychainGroup:cacheConfig.keychainGroup accessRef:cacheConfig.accessRef error:error];
    }
}
#endif

@end
