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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDB2COauth2Factory.h"
#import "MSIDB2CTokenResponse.h"
#import "MSIDOauth2Factory+Internal.h"
#import "MSIDAccessToken.h"
#import "MSIDIdToken.h"
#import "MSIDB2CAuthority.h"

@implementation MSIDB2COauth2Factory

+ (MSIDProviderType)providerType
{
    return MSIDProviderTypeB2C;
}

#pragma mark - Helpers

- (BOOL)checkResponseClass:(MSIDB2CTokenResponse *)response
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (![response isKindOfClass:[MSIDB2CTokenResponse class]])
    {
        if (error)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Wrong token response type passed, which means wrong factory is being used (expected MSIDB2CTokenResponse, passed %@", response.class];

            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorMessage, nil, nil, nil, context.correlationId, nil, YES);
        }

        return NO;
    }

    return YES;
}

#pragma mark - Response

- (MSIDB2CTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                        context:(__unused id<MSIDRequestContext>)context
                                          error:(NSError **)error
{
    return [[MSIDB2CTokenResponse alloc] initWithJSONDictionary:json error:error];
}

- (MSIDB2CTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                   refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                        context:(__unused id<MSIDRequestContext>)context
                                          error:(NSError * __autoreleasing *)error
{
    return [[MSIDB2CTokenResponse alloc] initWithJSONDictionary:json refreshToken:token error:error];
}

- (BOOL)verifyResponse:(MSIDB2CTokenResponse *)response
               context:(id<MSIDRequestContext>)context
                 error:(NSError * __autoreleasing *)error
{
    if (![self checkResponseClass:response context:context error:error])
    {
        return NO;
    }

    return [super verifyResponse:response context:context error:error];
}

#pragma mark - Tokens

- (BOOL)fillAccount:(MSIDAccount *)account
       fromResponse:(MSIDB2CTokenResponse *)response
      configuration:(MSIDConfiguration *)configuration
{
    if (![self checkResponseClass:response context:nil error:nil])
    {
        return NO;
    }

    BOOL result = [super fillAccount:account fromResponse:response configuration:configuration];

    if (!result)
    {
        return NO;
    }

    // B2C should return preferred_username claim
    if ([NSString msidIsStringNilOrBlank:response.idTokenObj.preferredUsername])
    {
        account.username = MSID_PREFERRED_USERNAME_MISSING;
    }

    return YES;
}

- (MSIDAuthority *)cacheAuthorityWithConfiguration:(MSIDConfiguration *)configuration
                                     tokenResponse:(MSIDTokenResponse *)response
{
    NSError *authorityError = nil;
    
    MSIDAuthority *cacheAuthority = [self resultAuthorityWithConfiguration:configuration tokenResponse:response error:&authorityError];
    
    if (!cacheAuthority)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, nil, @"Failed to create authority with error domain %@, code %ld", authorityError.domain, (long)authorityError.code);
        return nil;
    }
    
    return cacheAuthority;
}

#pragma mark - Authority

- (MSIDAuthority *)resultAuthorityWithConfiguration:(MSIDConfiguration *)configuration
                                      tokenResponse:(MSIDB2CTokenResponse *)response
                                              error:(NSError **)error
{
    return [[MSIDB2CAuthority alloc] initWithURL:configuration.authority.url
                                  validateFormat:NO
                                       rawTenant:response.clientInfo.utid
                                         context:nil
                                           error:error];
}

@end

#endif
