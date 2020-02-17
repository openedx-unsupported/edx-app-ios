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

#import "MSIDAADV2Oauth2Factory.h"
#import "MSIDAADV2TokenResponse.h"
#import "MSIDAccessToken.h"
#import "MSIDBaseToken.h"
#import "MSIDRefreshToken.h"
#import "MSIDLegacySingleResourceToken.h"
#import "MSIDAADV2IdTokenClaims.h"
#import "MSIDAuthority.h"
#import "MSIDAccount.h"
#import "MSIDIdToken.h"
#import "MSIDOauth2Factory+Internal.h"
#import "MSIDAADV2WebviewFactory.h"
#import "NSOrderedSet+MSIDExtensions.h"
#import "MSIDRequestParameters.h"
#import "MSIDAADAuthorizationCodeGrantRequest.h"
#import "MSIDAADRefreshTokenGrantRequest.h"
#import "MSIDWebviewConfiguration.h"
#import "MSIDInteractiveRequestParameters.h"
#import "MSIDAccountIdentifier.h"
#import "MSIDAADTokenResponseSerializer.h"
#import "MSIDClaimsRequest.h"
#import "MSIDClaimsRequest+ClientCapabilities.h"
#import "MSIDAADAuthority.h"

@implementation MSIDAADV2Oauth2Factory

#pragma mark - Helpers

- (BOOL)checkResponseClass:(MSIDTokenResponse *)response
                   context:(id<MSIDRequestContext>)context
                     error:(NSError **)error
{
    if (![response isKindOfClass:[MSIDAADV2TokenResponse class]])
    {
        if (error)
        {
            NSString *errorMessage = [NSString stringWithFormat:@"Wrong token response type passed, which means wrong factory is being used (expected MSIDAADV2TokenResponse, passed %@", response.class];

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
    return [[MSIDAADV2TokenResponse alloc] initWithJSONDictionary:json error:error];
}

- (MSIDTokenResponse *)tokenResponseFromJSON:(NSDictionary *)json
                                refreshToken:(MSIDBaseToken<MSIDRefreshableToken> *)token
                                     context:(__unused id<MSIDRequestContext>)context
                                       error:(NSError * __autoreleasing *)error
{
    return [[MSIDAADV2TokenResponse alloc] initWithJSONDictionary:json refreshToken:token error:error];
}

- (BOOL)verifyResponse:(MSIDAADV2TokenResponse *)response
               context:(id<MSIDRequestContext>)context
                 error:(NSError * __autoreleasing *)error
{
    if (![self checkResponseClass:response context:context error:error])
    {
        return NO;
    }

    BOOL result = [super verifyResponse:response context:context error:error];

    if (!result)
    {
        return result;
    }

    if (!response.clientInfo)
    {
        MSID_LOG_WITH_CTX(MSIDLogLevelError, context, @"Client info was not returned in the server response");
        
        if (error)
        {
            *error = MSIDCreateError(MSIDErrorDomain, MSIDErrorInternal, @"Client info was not returned in the server response", nil, nil, nil, context.correlationId, nil, NO);
        }
        return NO;
    }

    return YES;
}

#pragma mark - Tokens

- (BOOL)fillAccessToken:(MSIDAccessToken *)accessToken
           fromResponse:(MSIDAADV2TokenResponse *)response
          configuration:(MSIDConfiguration *)configuration
{
    BOOL result = [super fillAccessToken:accessToken fromResponse:response configuration:configuration];

    if (!result)
    {
        return NO;
    }

    // We want to keep case as it comes from the server side, because scopes are case sensitive by OIDC spec
    if (!accessToken.scopes)
    {
        accessToken.scopes = configuration.scopes;
    }

    return YES;
}

#pragma mark - Webview
- (MSIDWebviewFactory *)webviewFactory
{
    if (!_webviewFactory)
    {
        _webviewFactory = [[MSIDAADV2WebviewFactory alloc] init];
    }
    return _webviewFactory;
}

#pragma mark - Network requests

- (MSIDAuthorizationCodeGrantRequest *)authorizationGrantRequestWithRequestParameters:(MSIDRequestParameters *)parameters
                                                                         codeVerifier:(NSString *)pkceCodeVerifier
                                                                             authCode:(NSString *)authCode
                                                                        homeAccountId:(NSString *)homeAccountId
{
    MSIDClaimsRequest *claimsRequest = [MSIDClaimsRequest claimsRequestFromCapabilities:parameters.clientCapabilities
                                                                          claimsRequest:parameters.claimsRequest];
    NSString *claims = [[claimsRequest jsonDictionary] msidJSONSerializeWithContext:parameters];
    
    NSString *allScopes = parameters.allTokenRequestScopes;

    NSString *enrollmentId = nil;
    if (homeAccountId != parameters.accountIdentifier.homeAccountId)
    {
        // If there was an account switch during request (or no user account provided),
        // rely only on the homeAccountId from clientInfo obtained during auth code request.
        enrollmentId = [parameters.authority enrollmentIdForHomeAccountId:homeAccountId
                                                             legacyUserId:nil
                                                                  context:parameters
                                                                    error:nil];
    }
    else
    {
        enrollmentId = [parameters.authority enrollmentIdForHomeAccountId:parameters.accountIdentifier.homeAccountId
                                                             legacyUserId:parameters.accountIdentifier.displayableId
                                                                  context:parameters
                                                                    error:nil];
    }

    MSIDAADAuthorizationCodeGrantRequest *tokenRequest = [[MSIDAADAuthorizationCodeGrantRequest alloc] initWithEndpoint:parameters.tokenEndpoint
                                                                                                               clientId:parameters.clientId
                                                                                                           enrollmentId:enrollmentId
                                                                                                                  scope:allScopes
                                                                                                            redirectUri:parameters.redirectUri
                                                                                                                   code:authCode
                                                                                                                 claims:claims
                                                                                                           codeVerifier:pkceCodeVerifier
                                                                                                        extraParameters:parameters.extraTokenRequestParameters
                                                                                                                context:parameters];
    tokenRequest.responseSerializer = [[MSIDAADTokenResponseSerializer alloc] initWithOauth2Factory:self];

    return tokenRequest;
}

- (MSIDRefreshTokenGrantRequest *)refreshTokenRequestWithRequestParameters:(MSIDRequestParameters *)parameters
                                                              refreshToken:(NSString *)refreshToken
{
    MSIDClaimsRequest *claimsRequest = [MSIDClaimsRequest claimsRequestFromCapabilities:parameters.clientCapabilities
                                                                          claimsRequest:parameters.claimsRequest];
    NSString *claims = [[claimsRequest jsonDictionary] msidJSONSerializeWithContext:parameters];
    NSString *allScopes = parameters.allTokenRequestScopes;

    NSString *enrollmentId = [parameters.authority enrollmentIdForHomeAccountId:parameters.accountIdentifier.homeAccountId
                                                                   legacyUserId:parameters.accountIdentifier.displayableId
                                                                        context:parameters
                                                                          error:nil];

    MSIDAADRefreshTokenGrantRequest *tokenRequest = [[MSIDAADRefreshTokenGrantRequest alloc] initWithEndpoint:parameters.tokenEndpoint
                                                                                                     clientId:parameters.clientId
                                                                                                 enrollmentId:enrollmentId
                                                                                                        scope:allScopes
                                                                                                 refreshToken:refreshToken
                                                                                                       claims:claims
                                                                                              extraParameters:parameters.extraTokenRequestParameters
                                                                                                      context:parameters];
    tokenRequest.responseSerializer = [[MSIDAADTokenResponseSerializer alloc] initWithOauth2Factory:self];

    return tokenRequest;
}

#pragma mark - Authority

- (MSIDAuthority *)resultAuthorityWithConfiguration:(MSIDConfiguration *)configuration
                                      tokenResponse:(MSIDTokenResponse *)response
                                              error:(NSError **)error
{
    if (response.idTokenObj.realm)
    {
        return [MSIDAADAuthority aadAuthorityWithEnvironment:configuration.authority.environment
                                                   rawTenant:response.idTokenObj.realm
                                                     context:nil
                                                       error:error];
    }
    else
    {
        return configuration.authority;
    }
}

@end
