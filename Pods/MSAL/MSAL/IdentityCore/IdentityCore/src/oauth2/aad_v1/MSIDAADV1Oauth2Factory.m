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

#if !EXCLUDE_FROM_MSALCPP

#import "MSIDAADV1Oauth2Factory.h"
#import "MSIDAADV1TokenResponse.h"
#import "MSIDAccessToken.h"
#import "MSIDBaseToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDAccount.h"
#import "MSIDAuthorizeWebRequestConfiguration.h"
#import "MSIDAADV1IdTokenClaims.h"
#import "MSIDOauth2Factory+Internal.h"
#import "MSIDAuthority.h"
#import "MSIDIdToken.h"
#import "MSIDAuthority.h"
#import "MSIDOAuth2Constants.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAADV1WebviewFactory.h"
#import "MSIDAADAuthority.h"
#import "MSIDAADTenant.h"
#import "MSIDRefreshTokenGrantRequest.h"

@implementation MSIDAADV1Oauth2Factory

+ (MSIDProviderType)providerType
{
    return MSIDProviderTypeAADV1;
}

#pragma mark - Helpers

- (BOOL)checkResponseClass:(MSIDTokenResponse *)response
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (![response isKindOfClass:[MSIDAADV1TokenResponse class]])
    {
        if (error)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Wrong token response type passed, which means wrong factory is being used (expected MSIDAADV1TokenResponse, passed %@", response.class];

            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, errorMessage, nil, nil, nil, context.correlationId, nil, YES);
        }

        return NO;
    }

    return YES;
}

#pragma mark - Response

- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                     context:(__unused id<MSIDRequestContext>)context
                                       error:(NSError **)error
{
    return [[MSIDAADV1TokenResponse alloc] initWithJSONDictionary:json error:error];
}

- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                     context:(__unused id<MSIDRequestContext>)context
                                       error:(NSError * __autoreleasing *)error
{
    return [[MSIDAADV1TokenResponse alloc] initWithJSONDictionary:json refreshToken:token error:error];
}

- (BOOL)verifyResponse:(MSIDAADV1TokenResponse *)response
               context:(id<MSIDRequestContext>)context
                 error:(NSError * __autoreleasing *)error
{
    return [self verifyResponse:response
               fromRefreshToken:NO
                        context:context
                          error:error];
}

- (BOOL)verifyResponse:(MSIDAADV1TokenResponse *)response
      fromRefreshToken:(BOOL)fromRefreshToken
               context:(id<MSIDRequestContext>)context
                 error:(NSError * __autoreleasing *)error
{
    if (![self checkResponseClass:response context:context error:error])
    {
        return NO;
    }

    NSError *internalError = nil;
    BOOL result = [super verifyResponse:response context:context error:&internalError];

    if (!result)
    {
        if (internalError)
        {
            // In case of not overriden error code, change it to default error code for v1.
            if (internalError.code != MSIDErrorServerProtectionPoliciesRequired)
            {
                *error = MSIDCreateError(internalError.domain,
                                         fromRefreshToken ? MSIDErrorServerRefreshTokenRejected : MSIDErrorServerOauth,
                                         nil,
                                         nil,
                                         nil,
                                         nil,
                                         nil,
                                         internalError.userInfo, NO);
            }
            else
            {
                *error = internalError;
            }
        }

        return result;
    }

    if (!response.clientInfo)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelVerbose, context, @"Client info was not returned in the server response");
    }

    return YES;
}

#pragma mark - Tokens

- (BOOL)fillAccessToken:(MSIDAccessToken *)accessToken
           fromResponse:(MSIDAADV1TokenResponse *)response
          configuration:(MSIDConfiguration *)configuration
{
    BOOL result = [super fillAccessToken:accessToken fromResponse:response configuration:configuration];

    if (!result)
    {
        return NO;
    }

    accessToken.resource = response.target ? response.target : configuration.target;
    return YES;
}

- (BOOL)fillAccount:(MSIDAccount *)account
       fromResponse:(MSIDAADTokenResponse *)response
      configuration:(MSIDConfiguration *)configuration
{
    if (![super fillAccount:account fromResponse:response configuration:configuration])
    {
        return NO;
    }

    if (![self checkResponseClass:response context:nil error:nil])
    {
        return NO;
    }
    
    if (response.idTokenObj.realm)
    {
        account.realm = response.idTokenObj.realm;
    }
    
    return YES;
}

- (BOOL)fillIDToken:(MSIDIdToken *)token
       fromResponse:(MSIDTokenResponse *)response
      configuration:(MSIDConfiguration *)configuration
{
    if (![super fillIDToken:token fromResponse:response configuration:configuration])
    {
        return NO;
    }
    
    if (response.idTokenObj.realm)
    {
        token.realm = response.idTokenObj.realm;
    }

    return YES;
}

#pragma mark - Webview
- (MSIDWebviewFactory *)webviewFactory
{
    if (!_webviewFactory)
    {
        _webviewFactory = [[MSIDAADV1WebviewFactory alloc] init];
    }
    return _webviewFactory;
}

#pragma mark - Network requests

- (MSIDAuthorizationCodeGrantRequest *)authorizationGrantRequestWithRequestParameters:(__unused MSIDRequestParameters *)parameters
                                                                         codeVerifier:(__unused NSString *)pkceCodeVerifier
                                                                             authCode:(__unused NSString *)authCode
                                                                        homeAccountId:(__unused NSString *)homeAccountId
{
    // TODO: implement me for ADAL
    return nil;
}

- (MSIDRefreshTokenGrantRequest *)refreshTokenRequestWithRequestParameters:(__unused MSIDRequestParameters *)parameters
                                                              refreshToken:(__unused NSString *)refreshToken
{
    // TODO: implement me for ADAL
    return nil;
}

#pragma mark - Common identifiers

- (MSIDAccountIdentifier *)accountIdentifierFromResponse:(MSIDAADTokenResponse *)response
{
    return [[MSIDAccountIdentifier alloc] initWithDisplayableId:response.idTokenObj.userId
                                                  homeAccountId:response.clientInfo.accountIdentifier];
}

#pragma mark - Authority

- (MSIDAuthority *)resultAuthorityWithConfiguration:(__unused MSIDConfiguration *)configuration
                                      tokenResponse:(__unused MSIDTokenResponse *)response
                                              error:(__unused NSError **)error
{
    return configuration.authority;
}

@end

#endif
