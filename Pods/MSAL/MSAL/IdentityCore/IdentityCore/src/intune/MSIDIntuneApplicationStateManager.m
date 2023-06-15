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

#import "MSIDIntuneApplicationStateManager.h"
#import "MSIDAuthority.h"
#import "MSIDIntuneMAMResourcesCache.h"

@implementation MSIDIntuneApplicationStateManager

+ (BOOL)isAppCapableForMAMCA
{
#if TARGET_OS_IPHONE
    NSError *error = nil;
    NSDictionary *resourceCache = [[MSIDIntuneMAMResourcesCache sharedCache] resourcesJsonDictionaryWithContext:nil error:&error];
    
    if (error)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelWarning, nil, @"Failed to read Intune MAM resource cache with error %@", MSID_PII_LOG_MASKABLE(error));
        return NO;
    }
    
    return resourceCache.count > 0;
#else
    return NO;
#endif
}

+ (nullable NSString *)intuneApplicationIdentifierForAuthority:(MSIDAuthority *)authority
                                                 appIdentifier:(NSString *)appIdentifier
{
    if (authority.supportsMAMScenarios && [self isAppCapableForMAMCA])
    {
        return appIdentifier;
    }
    
    return nil;
}

@end
