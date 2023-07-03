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

#import "MSIDDefaultErrorConverter.h"
#import "MSIDError.h"

@implementation MSIDDefaultErrorConverter

- (NSError *)errorWithDomain:(NSString *)domain
                        code:(NSInteger)code
            errorDescription:(NSString *)errorDescription
                  oauthError:(NSString *)oauthError
                    subError:(NSString *)subError
             underlyingError:(NSError *)underlyingError
               correlationId:(NSUUID *)correlationId
                    userInfo:(NSDictionary *)additionalUserInfo
{
    if (!domain)
    {
        return nil;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary new];
    userInfo[MSIDErrorDescriptionKey] = errorDescription;
    userInfo[self.oauthErrorKey] = oauthError;
    userInfo[self.subErrorKey] = subError;
    userInfo[NSUnderlyingErrorKey] = underlyingError;
    userInfo[MSIDCorrelationIdKey] = [correlationId UUIDString];
    if (additionalUserInfo)
    {
        [userInfo addEntriesFromDictionary:additionalUserInfo];
    }

    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

- (NSString *)oauthErrorKey
{
    return MSIDOAuthErrorKey;
}

- (nonnull NSString *)subErrorKey
{
    return MSIDOAuthSubErrorKey;
}

@end
