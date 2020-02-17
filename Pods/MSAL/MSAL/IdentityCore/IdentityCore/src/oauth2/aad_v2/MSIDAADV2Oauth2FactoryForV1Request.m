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

#import "MSIDAADV2Oauth2FactoryForV1Request.h"
#import "MSIDOauth2Factory+Internal.h"
#import "MSIDV1IdToken.h"
#import "MSIDAADV2TokenResponseForV1Request.h"

@implementation MSIDAADV2Oauth2FactoryForV1Request

- (MSIDIdToken *)idTokenFromResponse:(MSIDTokenResponse *)response
                       configuration:(MSIDConfiguration *)configuration
{
    MSIDV1IdToken *idToken = [[MSIDV1IdToken alloc] init];
    
    BOOL result = [self fillIDToken:idToken fromResponse:response configuration:configuration];
    
    if (!result) return nil;
    return idToken;
}

- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                     context:(__unused id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    return [[MSIDAADV2TokenResponseForV1Request alloc] initWithJSONDictionary:json error:error];
}

- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                     context:(__unused id<MSIDRequestContext>)context
                                       error:(NSError * __autoreleasing *)error
{
    return [[MSIDAADV2TokenResponseForV1Request alloc] initWithJSONDictionary:json refreshToken:token error:error];
}

@end
